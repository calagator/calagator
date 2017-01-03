module Calagator

module EventsHelper
  include TimeRangeHelper # provides normalize_time

  def today_tomorrow_or_weekday(event)
    output = event.start_time.strftime('%A')
    output = "Started #{output}" if event.ongoing?
    output
  end

  # Cast date to_date unless date is undefined
  def format_event_date(date)
    date ? date.to_date : ""
  end

  # Cast date to time unless date is undefined
  def format_event_time(date)
    date ? date.strftime('%I:%M %p') : ""
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

    rowspans
  end

  def google_maps_url(address)
    "https://maps.google.com/maps?q=#{URI.encode(address)}"
  end

  #---[ Event sorting ]----------------------------------------------------

  # Return a link for sorting by +key+ (e.g., "name").
  def events_sort_link(key)
    if key.present?
      link_to(sorting_label_for(key, @tag.present?), url_for(params.merge(:order => key)))
    else
      link_to('Default', url_for(params.tap { |o| o.delete :order }))
    end
  end

  # Return a human-readable label describing what the sorting +key+ is.
  def events_sort_label(key)
    if key.present? or @tag.present?
      sanitize " by <strong>#{sorting_label_for(key, @tag.present?)}.</strong>"
    end
  end

  #---[ Feed links ]------------------------------------------------------

  # Returns a URL for an events feed.
  #
  # @param [Hash] filter Options for filtering. If values are defined, returns
  #   a link to all events. If a :query is defined, returns a link to search
  #   events' text by that query. If a :tag is defined, returns a link to search
  #   events with that tag.
  # @param [Hash] common Options for the URL helper, such as :protocol, :format
  #   and such.
  #
  # @raise [ArgumentError] Raised if given invalid filter options.
  #
  # @return [String] URL
  def _events_feed_linker(filter={}, common={})
    # Delete blank filter options because this method is typically called with
    # both a :tag and :query filter, but only one will actually be set.
    filter.delete_if { |key, value| value.blank? }

    if (unknown = filter.keys - [:query, :tag]).present?
      raise ArgumentError, "Unknown option(s): #{unknown.inspect}"
    end

    filter.present? ?
      search_events_url(common.merge(filter)) :
      events_url(common)
  end

  GOOGLE_EVENT_SUBSCRIBE_BASE = "https://www.google.com/calendar/render?cid="

  # Returns a Google Calendar subscription URL.
  #
  # @see #_events_feed_linker for details on parameters and exceptions.
  def google_events_subscription_link(filter={})
    link = _events_feed_linker(filter, format: "ics")
    "#{GOOGLE_EVENT_SUBSCRIBE_BASE}#{CGI.escape(link)}"
  end

  # Returns an iCalendar subscription URL.
  #
  # @see #_events_feed_linker for details on parameters and exceptions.
  def icalendar_feed_link(filter={})
    _events_feed_linker(filter, protocol: "webcal", format: "ics")
  end

  # Returns an iCalendar export URL.
  #
  # @see #_events_feed_linker for details on parameters and exceptions.
  def icalendar_export_link(filter={})
    _events_feed_linker(filter, format: "ics")
  end

  # Returns an ATOM subscription URL.
  #
  # @see #_events_feed_linker for details on parameters and exceptions.
  def atom_feed_link(filter={})
    _events_feed_linker(filter, format: "atom")
  end

  #--[ Sharing buttons ]-----------------------------------------

  # Tweet button text

  def tweet_text(event)
    lengths = tweet_text_sizer(event)

    result = []
    result << "#{truncate(event.title, length: lengths[:title])} -"
    result << event.start_time.strftime("%I:%M%p %m.%d.%Y") # "04:00PM 08.01.2012"
    result << "@ #{truncate(event.venue.title, length: lengths[:venue])}" if event.venue

    result.join(" ")
  end

  # Will increase the maximum length of either the event title or venue
  # if one of the two is shorter than the maximum: 46

  def tweet_text_sizer(event)
    title_length = event.title.length
    venue_length = (event.venue.try(:title) || "").length
    title_length = tweet_length(title_length, venue_length)
    venue_length = tweet_length(venue_length, title_length)
    { title: title_length, venue: title_length }
  end
  private :tweet_text_sizer

  def tweet_length length_a, length_b
    if length_a > 46
      length_a = 46
      length_a += (46-length_b) if length_b < 46
    end
    length_a
  end
  private :tweet_length

  def shareable_event_url(event)
    event_url(event) if event.persisted?
  end

  #---[ Sort labels ]-------------------------------------------

  # Return the label for the +sorting_key+ (e.g. 'score'). Optionally set the
  # +is_searching_by_tag+, to constrain options available for tag searches.
  def sorting_label_for(sorting_key=nil, is_searching_by_tag=false)
    sorting_key = sorting_key.to_s
    if sorting_key.present? and SORTING_LABELS.has_key?(sorting_key)
      SORTING_LABELS[sorting_key]
    elsif is_searching_by_tag
      SORTING_LABELS['date']
    else
      SORTING_LABELS['score']
    end
  end

  # Labels displayed for sorting options:
  SORTING_LABELS = {
    'name'  => 'Event Name',
    'venue' => 'Location',
    'score' => 'Relevance',
    'date'  => 'Date',
  }
  private_constant :SORTING_LABELS
end

end
