# frozen_string_literal: true

module Calagator
  module TagsHelper
    def tag_links_for(model)
      model.tags.sort_by(&:name).map do |tag|
        TagLink.new(model.class.table_name, tag, self).render
      end.join(", ").html_safe
    end

    class TagLink < Struct.new(:class_name, :tag, :context)
      def render
        context.link_to text, url, class: css_class
      end

      private

      def text
        icon = TagIcon.new(tag.name, context)
        i = icon.exists? ? icon.image_tag : nil
        [i, context.escape_once(tag.name)].compact.join(" ").html_safe
      end

      def url
        machine_tag.url || "/#{class_name}/tag/#{tag.name}"
      end

      def css_class
        classes = ["p-category"]
        if machine_tag.url
          classes += ["external", machine_tag.namespace, machine_tag.predicate]
        end
        classes.join(" ")
      end

      def machine_tag
        tag.machine_tag
      end
    end

    def display_tag_icons(event)
      event.tag_list.map do |tag_name|
        icon = TagIcon.new(tag_name, self)
        link_to(icon.image_tag, tag_events_path(tag_name)) if icon.exists?
      end.join(" ").html_safe
    end

    class TagIcon < Struct.new(:name, :context)
      def image_tag
        context.image_tag(image_path, title: name, alt: name)
      end

      def exists?
        if Rails.configuration.assets.compile
          Rails.application.precompiled_assets.include?(image_path)
        else
          Rails.application.assets_manifest.assets[image_path].present?
        end
      end

      private

      def image_path
        "tag_icons/#{name}.png"
      end
    end
  end
end
