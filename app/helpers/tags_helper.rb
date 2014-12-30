module TagsHelper
  def tag_links_for(model)
    model.tags.sort_by(&:name).map{|tag| tag_link(model.class.name.downcase.to_sym, tag)}.join(', ').html_safe
  end

  def tag_link(type, tag, link_class=nil)
    internal_url = "/#{type.to_s.pluralize}/tag/#{tag.name}"

    link_classes = [link_class, "p-category"]
    link_classes << "external #{tag.machine_tag[:namespace]} #{tag.machine_tag[:predicate]}" if tag.machine_tag[:url]

    link_text = [tag_icon(tag.name), escape_once(tag.name)].compact.join(' ').html_safe

    link_to link_text, (tag.machine_tag[:url] || internal_url), :class => link_classes.compact.join(' ')
  end
  private :tag_link

  def icon_exists_for?(tag_name)
    File.exists? Rails.root.join("app", "assets", "images", "tag_icons", "#{tag_name}.png")
  end

  def tag_icon(tag_name)
    if icon_exists_for?(tag_name)
      image_tag("/assets/tag_icons/#{tag_name}.png", title: tag_name)
    end
  end

  def get_tag_icon_links(event)
    event.tag_list.map do |tag_name|
      icon = tag_icon(tag_name)
      link_to(icon, tag_events_path(tag_name)) if icon
    end
  end

  def display_tag_icons(event)
    get_tag_icon_links(event).join(' ').html_safe
  end
end
