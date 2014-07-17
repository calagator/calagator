module DuplicateChecking
  class DuplicateSquasher < Struct.new(:model, :opts)
    def squash
      master     = opts[:master]
      duplicates = Array(opts[:duplicates])

      raise(ArgumentError, ":master not specified")     if master.blank?
      raise(ArgumentError, ":duplicates not specified") if duplicates.blank?

      squashed = []

      duplicates.each do |duplicate|
        next if !master.new_record? && !duplicate.new_record? && duplicate.id == master.id

        # Transfer any venues that use this now duplicate venue as a master
        unless duplicate.duplicates.blank?
          Rails.logger.debug("#{model.name}#squash: recursively squashing children of #{model.name}@#{duplicate.id}")
          self.class.new(model, :master => master, :duplicates => duplicate.duplicates).squash
        end

        # Transfer any has_many associations of this model to the master
        model.reflect_on_all_associations(:has_many).each do |association|
          next if association.name == :duplicates
          if model.duplicate_squashing_ignores_associations.include?(association.name.to_sym)
            Rails.logger.debug(%{#{model.name}#squash: skipping assocation '#{association.name}'})
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
            Rails.logger.debug(%{#{model.name}#squash: transferring foreign object "#{model.name}##{object.id}" from duplicate "#{model.name}##{duplicate.id}" to master "#{model.name}##{master.id}" via association "#{association.name}" using attribute "#{association.foreign_key}"})
          end
        end

        # TODO: Add support for habtm and other associations

        # Mark this as a duplicate
        duplicate.duplicate_of = master
        duplicate.update_attribute(:duplicate_of, master) unless duplicate.new_record?
        squashed << duplicate
        Rails.logger.debug("#{model.name}#squash: marking #{model.name}@#{duplicate.id} as duplicate of #{model.name}@#{master.id}")
      end
      squashed
    end

    private

    # custom behavior for tags, concatentate the two objects tag strings together
    def squash_tags(master, duplicate)
      master.tag_list = master.tag_list + duplicate.tag_list
      master.save_tags
    end
  end
end
