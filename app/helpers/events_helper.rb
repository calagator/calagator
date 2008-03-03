require 'uri'

module EventsHelper
  def today_tomorrow_or_weekday(record)
    if record.start_time.strftime('%Y:%j') == Time.today.strftime('%Y:%j')
      'Today'
    elsif record.start_time.strftime('%Y:%j') == (Time.today+1.day).strftime('%Y:%j')
      'Tomorrow'
    else
      record.start_time.strftime('%A')
    end
  end

  def normalize_time(time)
    datetime_format(time,time.min == 0 ? '%I%p' : '%I:%M%p').downcase
  end
  
  def google_maps_url(address)
    return "http://maps.google.com/maps?q=#{CGI::escape(address)}"
  end
end
