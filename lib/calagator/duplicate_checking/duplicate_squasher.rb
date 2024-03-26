# frozen_string_literal: true

module Calagator
  module DuplicateChecking
    class DuplicateSquasher < Struct.new(:primary, :duplicates, :model_name, :failure, :success)
      def duplicates
        Array(super)
      end

      def valid?
        name = model_name.split("::").last
        self.failure = "A primary #{name} must be selected." if primary.blank?
        if duplicates.empty?
          self.failure = "At least one duplicate #{name} must be selected."
        end
        if duplicates.include?(primary)
          self.failure = "The primary #{name} could not be squashed into itself."
        end
        failure.blank?
      end

      def squash
        if valid?
          duplicates.each do |duplicate|
            SingleSquasher.new(primary, duplicate, model_name).squash
          end
          name = model_name.split("::").last
          self.success = "Squashed duplicate #{name.pluralize} #{duplicates.map(&:title).sort} into primary #{primary.id}."
        end
        self
      end

      class SingleSquasher < Struct.new(:primary, :duplicate, :model_name)
        def squash
          # Transfer any venues that use this now duplicate venue as a primary
          if duplicate.duplicates.any?
            DuplicateSquasher.new(primary, duplicate.duplicates, model_name).squash
          end

          squash_associations

          duplicate.update_attribute(:duplicate_of, primary)
          duplicate
        end

        private

        def squash_associations
          # Transfer any has_many associations of this model to the primary
          primary.class.reflect_on_all_associations(:has_many).each do |association|
            next if association.name == :duplicates
            if primary.class.duplicate_squashing_ignores_associations.include?(association.name)
              next
            end

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
          primary.tag_list.add(primary.tag_list, duplicate.tag_list)
          primary.save_tags
        end

        def squash_association(association)
          foreign_objects = duplicate.send(association.name)
          foreign_objects.each do |object|
            object.update_attribute(association.foreign_key, primary.id)
          end
        end
      end
    end
  end
end
