module EventsHelper
  include TimeRangeHelper # provides normalize_time

  def today_tomorrow_or_weekday(record)
    # TODO Figure out if there's any need for this method beyond having a way of conditionally displaying the 'Started' information. As far as I can tell, there's no need to display the 'Today' or 'Tomorrow' rather than the weekday because each event already has a header to its left that can say 'Today' or 'Tomorrow'.
#    if record.start_time.to_date == Time.today.to_date
#      'Today'
#    elsif record.start_time.to_date == (Time.today+1.day).to_date
#      'Tomorrow'
#    elsif record.ongoing?
    if record.ongoing?
      "Started #{record.start_time.strftime('%A')}"
    else
      record.start_time.strftime('%A')
    end
  end

# calculate rowspans for an array of events
# argument:  array of events
# returns:  rowspans, an array in which each entry corresponds to an event in events;
# each entry is number of rows spanned by today_tomorrow_weekday entry, if any, to left of event
# entry will be > 0 for first event of day, 0 for other events
  def calculate_rowspans(events)
    previous_start_time = nil
    rowspans = Array.new(events.size, 0)
    first_event_of_day = 0

    events.each_with_index do |event, index|
      new_day = previous_start_time.nil? || (previous_start_time.to_date != event.start_time.to_date)
      if new_day
        first_event_of_day = index
      end
      rowspans[first_event_of_day] += 1
      previous_start_time = event.start_time
    end

    return rowspans
  end

  def google_maps_url(address)
    return "http://maps.google.com/maps?q=#{cgi_escape(address)}"
  end

  #---[ Event sorting ]----------------------------------------------------

  # Return a link for sorting by +key+ (e.g., "name").
  def events_sort_link(key)
    if key.present?
      link_to(Event::sorting_label_for(key, @tag.present?), url_for(params.merge(:order => key)))
    else
      link_to('Default', url_for(params.tap { |o| o.delete :order }))
    end
  end

  # Return a human-readable label describing what the sorting +key+ is.
  def events_sort_label(key)
    if key.present? or @tag.present?
      sanitize " by <strong>#{Event::sorting_label_for(key, @tag.present?)}.</strong>"
    else
      nil
    end
  end

  #---[ Google Calendar exporting ]-----------------------------------------

  # Time format used for Google Calendar exports
  GOOGLE_TIME_FORMAT = "%Y%m%dT%H%M%SZ"

  # Return a time span using Google Calendar's export format.
  def format_google_timespan(event)
    end_time = event.end_time || event.start_time
    "#{event.start_time.utc.strftime(GOOGLE_TIME_FORMAT)}/#{end_time.utc.strftime(GOOGLE_TIME_FORMAT)}"
  end

  # Return a Google Calendar export URL.
  def google_event_export_link(event)
    result = "http://www.google.com/calendar/event?action=TEMPLATE&trp=true&text=" << cgi_escape(event.title)

    result << "&dates=" << format_google_timespan(event)

    if event.venue
      result << "&location=" << cgi_escape(event.venue.title)
      if event.venue.geocode_address.present?
        result << cgi_escape(", " + event.venue.geocode_address)
      end
    end

    if event.url.present?
      result << "&sprop=website:" << cgi_escape(event.url.sub(/^http.?:\/\//, ''))
    end

    if event.description.present?
      details = "Imported from: #{event_url(event)} \n\n#{event.description}"
      details_suffix = "...[truncated]"
      overflow = 1024 - result.length
      if overflow > 0
        details = "#{details[0..(overflow - details.size - details_suffix.size - 1)]}#{details_suffix}"
      end
      result << "&details=" << cgi_escape(details)
    end

    return result
  end

end
