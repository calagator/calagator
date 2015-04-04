cache_if(@perform_caching, Calagator::CacheObserver.daily_key_for("events_atom", request)) do
  atom_feed("xmlns:georss".to_sym => "http://www.georss.org/georss") do |feed|
    page_title = if @search
      @search.tag ? "Events tagged with: #{@search.tag}" : "Search Results for: #{@search.query}"
    else
      "Events"
    end
    feed.title("#{Calagator.title}: #{page_title}")

    unless @events.size == 0
      feed.updated(@events.present? ? @events.sort_by(&:updated_at).last.updated_at : Time.now)

      for event in @events
        feed.entry(event) do |entry|
          summary = "#{normalize_time(event.start_time, event.end_time, :format => :text)}"
          summary += " at #{event.venue.title}" if event.venue && !event.venue.title.blank?

          entry.title(event.title)
          entry.summary(summary)
          entry.url(event_url(event))
          entry.link({:rel => 'enclosure', :type => 'text/calendar', :href => event_url(event, :format => 'ics') })
          entry.start_time(event.start_time.xmlschema)
          entry.end_time(event.end_time.xmlschema) if event.end_time
          entry.content(render(:partial => 'feed_item', :locals => {:event => event}, :formats => [:html]), :type => 'html')
          if event.venue && event.venue.latitude && event.venue.longitude
            entry.georss :point, "#{event.venue.latitude} #{event.venue.longitude}"
          end
        end
      end
    end
  end
end
