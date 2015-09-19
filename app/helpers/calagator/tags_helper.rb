module Calagator

module TagsHelper
  def tag_links_for(model)
    class_name = model.class.model_name.human.downcase.pluralize
    model.tags.sort_by(&:name).map do |tag|
      TagLink.new(class_name, tag, self).render
    end.join(', ').html_safe
  end

  class TagLink < Struct.new(:class_name, :tag, :context)
    def render
      internal_url = "/#{class_name}/tag/#{tag.name}"

      link_classes = ["p-category"]
      link_classes += ["external", tag.machine_tag.namespace, tag.machine_tag.predicate] if tag.machine_tag.url

      icon = TagIcon.new(tag.name, context)
      link_text = [icon.exists? && icon.image_tag, context.escape_once(tag.name)].compact.join(' ').html_safe

      context.link_to link_text, (tag.machine_tag.url || internal_url), class: link_classes.compact.join(' ')
    end
  end

  class TagIcon < Struct.new(:name, :context)
    def image_tag
      context.image_tag(image_path, title: name)
    end

    def exists?
      Rails.application.assets[image_path]
    end

    private

    def image_path
      "tag_icons/#{name}.png"
    end
  end

  def display_tag_icons(event)
    event.tag_list.map do |tag_name|
      icon = TagIcon.new(tag_name, self)
      link_to(icon.image_tag, tag_events_path(tag_name)) if icon.exists?
    end.join(' ').html_safe
  end
end

end
