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
      cattr_accessor(:_duplicate_checking_ignores_attributes) { Set.new }
      cattr_accessor(:_duplicate_squashing_ignores_associations) { Set.new }

      belongs_to :duplicate_of, :class_name => self.name, :foreign_key => DUPLICATE_MARK_COLUMN
      has_many   :duplicates,   :class_name => self.name, :foreign_key => DUPLICATE_MARK_COLUMN

      scope :marked_duplicates, -> { where("#{self.table_name}.#{DUPLICATE_MARK_COLUMN} IS NOT NULL") }
      scope :non_duplicates, -> { where("#{self.table_name}.#{DUPLICATE_MARK_COLUMN} IS NULL") }
    end
  end

  def duplicate?
    duplicate_of
  end
  alias_method :marked_as_duplicate?, :duplicate?
  alias_method :slave?, :duplicate?
  
  def master?
    !slave?
  end
  
  # Return the ultimate master for a record, which may be the record itself.
  def progenitor
    parent = self
    seen = Set.new

    loop do
      return parent if parent.master?
      raise DuplicateCheckingError, "Loop detected in duplicates chain at #{parent.class}##{parent.id}" if seen.include?(parent)
      seen << parent
      parent = parent.duplicate_of
    end
  end
  
  # Return either an Array of exact duplicates for this record, or nil if no exact duplicates were found.
  #
  # Note that this method requires that all associations are set before this method is called.
  def find_exact_duplicates
    matchable_attributes = attributes.reject { |key, value|
      self.class.duplicate_checking_ignores_attributes.include?(key.to_sym)
    }
    duplicates = self.class.where(matchable_attributes).reject{|t| t.id == id}
    duplicates.blank? ? nil : duplicates
  end

  module ClassMethods
    # Return set of attributes that should be ignored for duplicate checking
    def duplicate_checking_ignores_attributes(*args)
      _duplicate_checking_ignores_attributes.merge(args.map(&:to_sym)) unless args.empty?
      DUPLICATE_CHECKING_IGNORES_ATTRIBUTES + _duplicate_checking_ignores_attributes
    end

    # Return set of associations that will be ignored during duplicate squashing
    def duplicate_squashing_ignores_associations(*args)
      _duplicate_squashing_ignores_associations.merge(args.map(&:to_sym)) unless args.empty?
      _duplicate_squashing_ignores_associations
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
      DuplicateFinder.new(self, fields, options).find
    end

    # Squash duplicates. Options accept ActiveRecord instances or IDs.
    #
    # Options:
    # :duplicates => ActiveRecord instance(s) to mark as duplicates
    # :master => ActiveRecord instance to use as master
    def squash(opts)
      master     = opts[:master]
      duplicates = Array(opts[:duplicates])

      raise(ArgumentError, ":master not specified")     if master.blank?
      raise(ArgumentError, ":duplicates not specified") if duplicates.blank?

      squashed = []

      duplicates.each do |duplicate|
        next if !master.new_record? && !duplicate.new_record? && duplicate.id == master.id

        # Transfer any venues that use this now duplicate venue as a master
        unless duplicate.duplicates.blank?
          Rails.logger.debug("#{self.name}#squash: recursively squashing children of #{self.name}@#{duplicate.id}")
          squash(:master => master, :duplicates => duplicate.duplicates)
        end

        # Transfer any has_many associations of this model to the master
        reflect_on_all_associations(:has_many).each do |association|
          next if association.name == :duplicates
          if duplicate_squashing_ignores_associations.include?(association.name.to_sym)
            Rails.logger.debug(%{#{name}#squash: skipping assocation '#{association.name}'})
            next
          end

          # Handle tags - can't simply reassign, need to be unique, and they may have some of the same tags
          if association.name == :tag_taggings
            squash_tags(master, duplicate)
            next
          end

          foreign_objects = duplicate.send(association.name)
          foreign_objects.each do |object|
            object.update_attribute(association.foreign_key, master.id) unless object.new_record?
            Rails.logger.debug(%{#{name}#squash: transferring foreign object "#{object.class.name}##{object.id}" from duplicate "#{name}##{duplicate.id}" to master "#{name}##{master.id}" via association "#{association.name}" using attribute "#{association.foreign_key}"})
          end
        end

        # TODO: Add support for habtm and other associations

        # Mark this as a duplicate
        duplicate.duplicate_of = master
        duplicate.update_attribute(:duplicate_of, master) unless duplicate.new_record?
        squashed << duplicate
        Rails.logger.debug("#{name}#squash: marking #{name}@#{duplicate.id} as duplicate of #{name}@#{master.id}")
      end
      squashed
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
