module DuplicateChecking
  class DuplicateSquasher < Struct.new(:model, :opts)
    def squash
      raise(ArgumentError, ":master not specified")     if master.blank?
      raise(ArgumentError, ":duplicates not specified") if duplicates.blank?

      duplicates.each do |duplicate|
        squash_duplicate duplicate
      end
    end

    private

    def master
      opts[:master]
    end

    def duplicates
      Array(opts[:duplicates])
    end

    def squash_duplicate duplicate
      # Transfer any venues that use this now duplicate venue as a master
      if duplicate.duplicates.any?
        self.class.new(model, :master => master, :duplicates => duplicate.duplicates).squash
      end

      # Transfer any has_many associations of this model to the master
      model.reflect_on_all_associations(:has_many).each do |association|
        next if association.name == :duplicates
        next if model.duplicate_squashing_ignores_associations.include?(association.name)

        # Handle tags - can't simply reassign, need to be unique, and they may have some of the same tags
        if association.name == :tag_taggings
          squash_tags(duplicate)
        else
          squash_association(duplicate, association)
        end
      end

      # TODO: Add support for habtm and other associations

      duplicate.update_attribute(:duplicate_of, master)
      duplicate
    end

    # custom behavior for tags, concatentate the two objects tag strings together
    def squash_tags(duplicate)
      master.tag_list = master.tag_list + duplicate.tag_list
      master.save_tags
    end

    def squash_association(duplicate, association)
      foreign_objects = duplicate.send(association.name)
      foreign_objects.each do |object|
        object.update_attribute(association.foreign_key, master.id)
      end
    end
  end
end
