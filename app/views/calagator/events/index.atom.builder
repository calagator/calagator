# frozen_string_literal: true

cache_if(@perform_caching, Calagator::CacheObserver.daily_key_for('events_atom', request)) do
  atom_feed('xmlns:georss'.to_sym => 'http://www.georss.org/georss') do |feed|
    page_title = if @search
                   @search.tag ? "Events tagged with: #{@search.tag}" : "Search Results for: #{@search.query}"
                 else
                   'Events'
    end
    feed.title("#{Calagator.title}: #{page_title}")

    unless @events.empty?
      feed.updated(@events.present? ? @events.max_by(&:updated_at).updated_at : Time.now.in_time_zone)

      @events.each do |event|
        feed.entry(event) do |entry|
          summary = normalize_time(event.start_time, event.end_time, format: :text).to_s
          if event.venue && event.venue.title.present?
            summary += " at #{event.venue.title}"
          end

          entry.title(event.title)
          entry.summary(summary)
          entry.url(event_url(event))
          entry.link(rel: 'enclosure', type: 'text/calendar', href: event_url(event, format: 'ics'))
          entry.start_time(event.start_time.xmlschema)
          entry.end_time(event.end_time.xmlschema) if event.end_time
          entry.content(render(partial: 'feed_item', locals: { event: event }, formats: [:html]), type: 'html')
          if event.venue&.latitude && event.venue&.longitude
            entry.georss :point, "#{event.venue.latitude} #{event.venue.longitude}"
          end
        end
      end
    end
  end
end
