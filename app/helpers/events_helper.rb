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
    return "http://maps.google.com/maps?q=#{CGI::escape(address)}"
  end

  #---[ Event sorting ]----------------------------------------------------

  # Return a link for sorting by +key+ (e.g., "name").
  def events_sort_link(key)
    link_to(Event::sorting_label_for(key, @tag.present?), url_for(params.merge(:order => key)))
  end

  # Return a human-readable label describing what the sorting +key+ is.
  def events_sort_label(key)
    if key.present? or @tag.present?
      " by <strong>#{Event::sorting_label_for(key, @tag.present?)}.</strong>"
    else
      nil
    end
  end

  #---[ Google Calendar exporting ]-----------------------------------------

  GOOGLE_TIME_FORMAT = "%Y%m%dT%H%M%SZ"

  def format_google_timespan( event)
    end_time = event.end_time || event.start_time
    "#{event.start_time.utc.strftime(GOOGLE_TIME_FORMAT)}/#{end_time.utc.strftime(GOOGLE_TIME_FORMAT)}"
  end
  
  def google_event_export_link(event)
    # TODO trim
    title = CGI::escape(event.title.strip_html)
    dates = format_google_timespan(event)
    details = CGI::escape(event.description || "")
    venue = CGI::escape(event.venue ? (event.venue.geocode_address.blank? ? '' : event.venue.geocode_address) : '')
    "http://www.google.com/calendar/event?action=TEMPLATE&text=#{title}&dates=#{dates}&details=#{details}&location=#{venue}&trp=true&sprop=#{event.url}&sprop=name:"
  end
  
end
