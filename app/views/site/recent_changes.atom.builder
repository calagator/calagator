atom_feed() do |feed|
  feed.title("Calagator: Recent Changes")
  unless @items.size == 0
    feed.updated(@items.sort_by(&:updated_at).last.updated_at)

    for item in @items
      object = item.send(item.class.parent.name.downcase)
      feed.entry(object) do |entry|        
        entry.title("#{item.title} : Version #{item.version}");
        entry.summary("#{item.title} : Version #{item.version}")
        entry.url(url_for object)
        entry.updated(item.updated_at)
        entry.published(item.updated_at)
        entry.content(render(:partial => 'change.html.erb', :locals => {:item => item, :object => object }), :type => 'html')
      end
    end
  end
end
