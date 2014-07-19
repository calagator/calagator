module DuplicateChecking
  class DuplicateSquasher < Struct.new(:master, :duplicates)
    def initialize(opts)
      self.master = opts[:master]
      self.duplicates = Array(opts[:duplicates])
    end

    def squash
      raise(ArgumentError, ":master not specified")     if master.blank?
      raise(ArgumentError, ":duplicates not specified") if duplicates.empty?

      duplicates.each do |duplicate|
        SingleSquasher.new(master, duplicate).squash
      end
    end

    class SingleSquasher < Struct.new(:master, :duplicate)
      def squash
        # Transfer any venues that use this now duplicate venue as a master
        if duplicate.duplicates.any?
          self.class.squash master: master, duplicates: duplicate.duplicates
        end

        squash_associations

        duplicate.update_attribute(:duplicate_of, master)
        duplicate
      end

      private

      # TODO: Add support for habtm and other associations
      def squash_associations
        # Transfer any has_many associations of this model to the master
        master.class.reflect_on_all_associations(:has_many).each do |association|
          next if association.name == :duplicates
          next if master.class.duplicate_squashing_ignores_associations.include?(association.name)

          # Handle tags - can't simply reassign, need to be unique, and they may have some of the same tags
          if association.name == :tag_taggings
            squash_tags
          else
            squash_association association
          end
        end
      end

      # custom behavior for tags, concatentate the two objects tag strings together
      def squash_tags
        master.tag_list = master.tag_list + duplicate.tag_list
        master.save_tags
      end

      def squash_association(association)
        foreign_objects = duplicate.send(association.name)
        foreign_objects.each do |object|
          object.update_attribute(association.foreign_key, master.id)
        end
      end
    end
  end
end
