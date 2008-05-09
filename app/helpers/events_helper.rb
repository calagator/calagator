module EventsHelper
  include TimeRangeHelper # provides normalize_time

  GOOGLE_TIME_FORMAT = "%Y%m%dT%H%M%SZ"

  def today_tomorrow_or_weekday(record)
    if record.start_time.strftime('%Y:%j') == Time.today.strftime('%Y:%j')
      'Today'
    elsif record.start_time.strftime('%Y:%j') == (Time.today+1.day).strftime('%Y:%j')
      'Tomorrow'
    else
      record.start_time.strftime('%A')
    end
  end

  def google_maps_url(address)
    return "http://maps.google.com/maps?q=#{CGI::escape(address)}"
  end

  def format_google_timespan( event)
    end_time = event.end_time || event.start_time
    "#{local_to_utc(event.start_time).strftime( GOOGLE_TIME_FORMAT)}/#{local_to_utc(end_time).strftime( GOOGLE_TIME_FORMAT)}"
  end

private

  # Convert a +time+ from the local timezone to UTC.
  def local_to_utc(time)
    local = TZ.local_to_utc(time)
  end
end
