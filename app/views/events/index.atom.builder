atom_feed() do |feed|
  feed.title("Calagator")
  unless @events.size == 0
    feed.updated(@events.sort_by(&:updated_at).last.updated_at)

    for event in @events
      feed.entry(event) do |entry|
        entry.title(event.title)
        entry.url(event_url(event))
        entry.updated(event.updated_at)
        entry.link({:rel => 'enclosure', :type => 'text/calendar', :href => formatted_event_url(event,'ics') })
        entry.content(render(:partial => 'events/feed_item.html.erb', :locals => { :event => event }), :type => 'html')
      end
    end
  end
end