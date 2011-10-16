# = DuplicateChecking
#
# This mixin provides a way for ActiveRecord classes to find and squash duplicates.
#
# Example:
#
#   # Define your class
#   class Thing < ActiveRecord::Base
#     # Load the mixin into your class
#     include DuplicateChecking
#
#     # Declare attributes that should be ignored during duplicate checks
#     duplicate_checking_ignores_attributes :random_value
#
#     # Declare associations that should be ignored during duplicate squashing
#     duplicate_squashing_ignores_associations :tags
#   end
#
#   # Set duplicates on objects
#   foo1 = Thing.create!!:name => "foo")
#   foo2 = Thing.create!(:name => "foo", :duplicate_of => foo1)
#   bar  = Thing.create!(:name => "bar")
#
#   # Check whether record is set as duplicate
#   foo1.duplicate? # => false
#   foo2.duplicate? # => true
#   bar.duplicate?  # => false
#
#   # Find duplicate of a record
#   foo3.find_exact_duplicates # => [foo1, foo2]
#   bar.find_exact_duplicates  # => nil
module DuplicateChecking
  DUPLICATE_MARK_COLUMN = :duplicate_of_id
  DEFAULT_SQUASH_METHOD = :mark
  DUPLICATE_CHECKING_IGNORES_ATTRIBUTES =
    Set.new((%w(created_at updated_at id) + [DUPLICATE_MARK_COLUMN]).map(&:to_sym))

  def self.included(base)
    base.extend ClassMethods
    base.class_eval do
      cattr_accessor :_duplicate_checking_ignores_attributes
      self._duplicate_checking_ignores_attributes = Set.new

      cattr_accessor :_duplicate_squashing_ignores_associations
      self._duplicate_squashing_ignores_associations = Set.new

      belongs_to :duplicate_of, :class_name => self.name, :foreign_key => DUPLICATE_MARK_COLUMN
      has_many   :duplicates,   :class_name => self.name, :foreign_key => DUPLICATE_MARK_COLUMN

      scope :marked_duplicates, :conditions => "#{self.table_name}.#{DUPLICATE_MARK_COLUMN} IS NOT NULL"
      scope :non_duplicates, :conditions => "#{self.table_name}.#{DUPLICATE_MARK_COLUMN} IS NULL"
    end
  end

  # Is this record marked as a duplicate?
  def marked_as_duplicate?
    !self.duplicate_of_id.blank?
  end
  
  # Is this record a squashed duplicate of an existing record?
  def duplicate?
    !self.duplicate_of.blank?
  end

  def slave?
    self.duplicate?
  end
  
  def master?
    !self.slave?
  end
  
  # Return the ultimate master for a record, which may be the record itself.
  def progenitor
    parent = self
    seen = Set.new

    while true
      if parent.master?
        return parent
      else
        if seen.include?(parent)
          raise DuplicateCheckingError, "Loop detected in duplicates chain at #{parent.class}##{parent.id}"
        else
          seen << parent
          parent = parent.duplicate_of
        end
      end
    end
  end
  
  # Return either an Array of exact duplicates for this record, or nil if no exact duplicates were found.
  #
  # Note that this method requires that all associations are set before this method is called.
  def find_exact_duplicates
    matchable_attributes = self.attributes.reject { |key, value|
      self.class.duplicate_checking_ignores_attributes.include?(key.to_sym)
    }
    duplicates = self.class.where(matchable_attributes).reject{|t| t.id == self.id}
    return duplicates.blank? ? nil : duplicates
  end

  module ClassMethods

    # Return set of attributes that should be ignored for duplicate checking
    def duplicate_checking_ignores_attributes(*args)
      unless args.empty?
        self._duplicate_checking_ignores_attributes.merge(args.map(&:to_sym))
      end
      return(DUPLICATE_CHECKING_IGNORES_ATTRIBUTES + self._duplicate_checking_ignores_attributes)
    end

    # Return set of associations that will be ignored during duplicate squashing
    def duplicate_squashing_ignores_associations(*args)
      unless args.empty?
        self._duplicate_squashing_ignores_associations.merge(args.map(&:to_sym))
      end
      return self._duplicate_squashing_ignores_associations
    end

    # Return events with duplicate values for a given set of fields.
    #
    # Options:
    # * :grouped => Return Hash of events grouped by commonality, rather than returning an Array. Defaults to false.
    # * :where => String that specifies additional arguments to add to the WHERE clause.
    # * :select => String that specified additional arguments to add to the SELECT clause.
    # * :from => String that specifies additional arguments to add to the FROM clause
    # * :joins => String that specifies additional argument to add to a JOINS clause.
    def find_duplicates_by(fields, options={})
      grouped = options[:grouped] || false
      selections = ['a.*', options[:select]].compact.join(', ')
      froms = ["#{table_name} a", "#{table_name} b", options[:from]].compact.join(', ')
      froms << " #{options[:joins]}" if options[:joins]
      query = "SELECT DISTINCT #{selections} from #{froms} WHERE"
      query << " #{options[:where]} AND " if options[:where]
      query << " a.id <> b.id AND ("
      attributes = new.attribute_names
      matched_fields = nil

      if fields.nil? || (fields.respond_to?(:blank?) && fields.blank?)
        fields = :all
      end

      if fields == :all || fields == :any
        matched = false
        attributes.each do |attr|
          # TODO make find_duplicates_by(:all) pay attention to ignore fields
          next if ['id','created_at','updated_at', 'duplicate_of_id','version'].include?(attr)
          if fields == :all
            query << " AND" if matched
            query << " ((a.#{attr} = b.#{attr}) OR (a.#{attr} IS NULL AND b.#{attr} IS NULL))"
          else
            query << " OR" if matched
            query << " (a.#{attr} = b.#{attr} AND ("
            column = self.columns.find {|column| column.name == attr}
            case column.type
            when :integer, :decimal
              query << "a.#{attr} != 0 AND "
            when :string, :text
              query << "a.#{attr} != '' AND "
            end
            query << "a.#{attr} IS NOT NULL))"
          end
          matched = true
        end
      else
        matched = false
        fields = [fields].flatten
        fields.each do |attr|
          if attributes.include?(attr.to_s)
            query << " AND" if matched
            query << " a.#{attr} = b.#{attr}"
            matched = true
          else
            raise ArgumentError, "Unknow fields: #{fields.inspect}"
          end
        end
        matched_fields = lambda {|r| fields.map {|f| r.read_attribute(f.to_sym) }}
      end

      query << " )"

      Rails.logger.debug("find_duplicates_by: SQL -- #{query}")
      records = find_by_sql(query) || []

      # Reject known duplicates
      records.reject! {|t| t.duplicate_of_id} if records.first.respond_to?(:duplicate_of_id)

      if grouped
        # Group by the field values we're matching on; skip any values for which we only have one record
        records.group_by { |record| matched_fields.call(record) if matched_fields }\
               .reject { |value, group| group.size <= 1 }
      else
        records
      end
    end

    # Returns an ActiveRecord object associated with the +value+, which can be either a record or an ID
    def _record_for(value)
      case value
      when self then value # Expected class already, do nothing
      when String, Fixnum, Bignum then self.find(value.to_i)
      else raise TypeError, "Unknown type: #{value.class}"
      end
    end

    # Squash duplicates. Options accept ActiveRecord instances or IDs.
    #
    # Options:
    # :duplicates => ActiveRecord instance(s) to mark as duplicates
    # :master => ActiveRecord instance to use as master
    def squash(opts)
      master     = opts[:master]
      duplicates = [opts[:duplicates]].flatten

      raise(ArgumentError, ":master not specified")     if master.blank?
      raise(ArgumentError, ":duplicates not specified") if duplicates.blank?

      master = _record_for(master)

      squashed = []

      for duplicate in duplicates
        duplicate = _record_for(duplicate)

        next if !master.new_record? && !duplicate.new_record? && duplicate.id == master.id

        # Transfer any venues that use this now duplicate venue as a master
        unless duplicate.duplicates.blank?
          Rails.logger.debug("#{self.name}#squash: recursively squashing children of #{self.name}@#{duplicate.id}")
          squash(:master => master, :duplicates => duplicate.duplicates)
        end

        # Transfer any has_many associations of this model to the master
        self.reflect_on_all_associations(:has_many).each do |association|
          next if association.name == :duplicates
          if self.duplicate_squashing_ignores_associations.include?(association.name.to_sym)
            Rails.logger.debug(%{#{self.name}#squash: skipping assocation '#{association.name}'})
            next
          end

          # Handle tags - can't simply reassign, need to be unique, and they may have some of the same tags
          if association.name == :tag_taggings
            squash_tags(master, duplicate)
            next
          end

          foreign_objects = duplicate.send(association.name)
          for object in foreign_objects
            object.update_attribute(association.primary_key_name, master.id) unless object.new_record?
            Rails.logger.debug(%{#{self.name}#squash: transferring foreign object "#{object.class.name}##{object.id}" from duplicate "#{self.name}##{duplicate.id}" to master "#{self.name}##{master.id}" via association "#{association.name}" using attribute "#{association.primary_key_name}"})
          end
        end

        # TODO: Add support for habtm and other associations

        # Mark this as a duplicate
        duplicate.duplicate_of = master
        duplicate.update_attribute(:duplicate_of, master) unless duplicate.new_record?
        squashed << duplicate
        Rails.logger.debug("#{self.name}#squash: marking #{self.name}@#{duplicate.id} as duplicate of #{self.name}@{master.id}")
      end
      return squashed
    end

    # custom behavior for tags, concatentate the two objects tag strings together
    def squash_tags(master, duplicate)
      master.tag_list = master.tag_list + duplicate.tag_list
      master.save_tags
    end

  end
end

class DuplicateCheckingError < Exception
end
