require 'uri'

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
    "#{portland_to_utc(event.start_time).strftime( GOOGLE_TIME_FORMAT)}/#{portland_to_utc(end_time).strftime( GOOGLE_TIME_FORMAT)}"
  end
  
  private
  
  def portland_to_utc( p)
    # TODO: fix this before Pacific Daylight Time (UTC -7) turns to Pacific Standard Time (UTC -8)
    DateTime.civil( p.year, p.month, p.day, p.hour + 7, p.min, p.sec)
  end
end
