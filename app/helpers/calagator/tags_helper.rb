module Calagator

module TagsHelper
  def tag_links_for(model)
    class_name = model.class.model_name.human.downcase.pluralize
    model.tags.sort_by(&:name).map do |tag|
      tag_link(class_name, tag)
    end.join(', ').html_safe
  end

  def tag_link(class_name, tag, link_class=nil)
    internal_url = "/#{class_name}/tag/#{tag.name}"

    link_classes = [link_class, "p-category"]
    link_classes += ["external", tag.machine_tag.namespace, tag.machine_tag.predicate] if tag.machine_tag.url

    link_text = [tag_icon(tag.name), escape_once(tag.name)].compact.join(' ').html_safe

    link_to link_text, (tag.machine_tag.url || internal_url), class: link_classes.compact.join(' ')
  end
  private :tag_link

  def tag_icon(tag_name)
    return unless icon_exists_for?(tag_name)
    image_tag(asset_path(tag_icon_path(tag_name)), title: tag_name)
  end
  private :tag_icon

  def icon_exists_for?(tag_name)
    !!Rails.application.assets[tag_icon_path(tag_name)]
  end
  private :icon_exists_for?

  def tag_icon_path(tag_name)
    "tag_icons/#{tag_name}.png"
  end
  private :tag_icon_path

  def display_tag_icons(event)
    get_tag_icon_links(event).join(' ').html_safe
  end

  def get_tag_icon_links(event)
    event.tag_list.map do |tag_name|
      icon = tag_icon(tag_name)
      link_to(icon, tag_events_path(tag_name)) if icon
    end
  end
  private :get_tag_icon_links

end

end
