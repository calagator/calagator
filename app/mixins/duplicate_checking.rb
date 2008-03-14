module DuplicateChecking
  DUPLICATE_MARK_COLUMN = 'duplicate_of_id'
  DEFAULT_SQUASH_METHOD = :mark
  
  def self.included(base)
    base.extend ClassMethods
    base.class_eval do
      belongs_to :duplicate_of, :class_name => self.name, :foreign_key => DUPLICATE_MARK_COLUMN
      has_many :duplicates, :class_name => self.name, :foreign_key => DUPLICATE_MARK_COLUMN
      class << self
        VALID_FIND_OPTIONS << :duplicates
        alias_method_chain :find, :duplicate_support
      end
    end
  end
  
  module ClassMethods
    
    # Extends ActiveRecord find with support for duplicates. 
    #
    # find(:duplicates) => finds duplicates by a given set of fields
    #   Class.find(:duplicates) # finds duplicates with all fields matching
    #   Class.find(:duplicates, :by => :title) # finds duplicates with matching titles
    #   Class.find(:duplicates, :by => [:title, :description]) # finds duplicates with matching titles and description
    #
    # find(:marked_duplicates) => finds entries that have been marked as a duplicate of another entry.
    #
    # find(:non_duplicates) => finds entries that have not been marked as duplicate
    #
    def find_with_duplicate_support(*args)
      case args.first.to_sym
      when :duplicates
        fields = args.last.is_a?(Hash) && args.last.has_key?(:by) ? args.last[:by] : :all
        return find_duplicates_by(fields)
      when :marked_duplicates
        condition = "#{DUPLICATE_MARK_COLUMN} IS NOT NULL"
      when :non_duplicates
        condition = "#{DUPLICATE_MARK_COLUMN} IS NULL"
      end
      if !condition.nil?
        if !new.attribute_names.include?('duplicate_of_id')
          raise ArgumentError, "#{table_name} is not set up to track duplicates."
        end
        args[0] = :all
        if args[1].is_a?(Hash)
          args[1][:conditions] = condition 
        else
          args[1] = {:conditions => condition}
        end
        #TODO: Merge with existing conditions to further filter duplicate searching.
        find_without_duplicate_support(*args)
      else
        find_without_duplicate_support(*args)
      end
    end
    
    # Return an array of events with duplicate values for a given set of fields
    def find_duplicates_by(fields)
      query = "SELECT DISTINCT a.* from #{table_name} a, #{table_name} b WHERE a.id <> b.id AND ("
      attributes = new.attribute_names

      if fields == :all || fields == :any
        attributes.each do |attr|
          next if ['id','created_at','updated_at', 'duplicate_of_id'].include?(attr)
          if fields == :all
            query += " a.#{attr} = b.#{attr} AND"
          else
            query += " (a.#{attr} = b.#{attr} AND (a.#{attr} != '' AND a.#{attr} != 0 AND a.#{attr} NOT NULL)) OR "
          end
        end
      else
        fields = [fields].flatten
        fields.each do |attr|
            query += " a.#{attr} = b.#{attr} AND" if attributes.include?(attr.to_s)
        end
        order = fields.join(',a.')
      end
      order ||= 'id'
      query = query[0..-4] + ") ORDER BY a.#{order}"

      RAILS_DEFAULT_LOGGER.debug("find_duplicates_by: SQL -- #{query}")

      # TODO Refactor SQL generator to reject known duplicates
      records = find_by_sql(query)
      if records.nil?
        []
      elsif records.first.respond_to?(:duplicate_of_id)
        records.reject{|t| t.duplicate_of_id}
      else
        records
      end
    end
    
    # Squash duplicates. Options accept Venue instances or IDs.
    #
    # Options:
    # :duplicates => Venue(s) to mark as duplicates
    # :master => Venue to use as master
    def squash(opts)
      master     = opts[:master]
      duplicates = [opts[:duplicates]].flatten

      raise(ArgumentError, ":master not specified")     if master.blank?
      raise(ArgumentError, ":duplicates not specified") if duplicates.blank?
      
      case master
      when self # Expected class, do nothing
      when String, Fixnum then master = self.find(master.to_i)
      else raise TypeError, "Unknown :master type: #{master.class}"
      end

      for duplicate in duplicates
        case duplicate
        when self # Expected class, do nothing
        when String, Fixnum then duplicate = self.find(duplicate.to_i)
        else raise TypeError, "Unknown :duplicate type: #{duplicate.class}"
        end
        
        next if duplicate.id == master.id

        # Transfer any venues that use this now duplicate venue as a master
        unless duplicate.duplicates.blank?
          RAILS_DEFAULT_LOGGER.debug("#{self.name}#squash: recursively squashing children of #{self.name}@#{duplicate.id}")
          squash(:master => master, :duplicates => duplicate.duplicates)
        end
        
        # Transfer any has_many associations of this model to the master
        self.reflect_on_all_associations(:has_many).each do |association|
          next if association.name == :duplicates
          foreign_objects = duplicate.send(association.name)
          for object in foreign_objects
            object.update_attribute(association.primary_key_name, master.id) unless object.new_record?
            RAILS_DEFAULT_LOGGER.debug("#{self.name}#squash: transfering #{object.class.name}@#{object.id} from #{self.name}@#{duplicate.id} to #{self.name}@{master.id}")
          end
        end
        
        # TODO: Add support for habtm and other associations

        # Mark this as a duplicate
        duplicate.duplicate_of = master
        duplicate.update_attribute(:duplicate_of, master) unless duplicate.new_record?
        RAILS_DEFAULT_LOGGER.debug("#{self.name}#squash: marking #{self.name}@#{duplicate.id} as duplicate of #{self.name}@{master.id}")
      end
    end
    
  end
end
