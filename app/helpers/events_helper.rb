require 'uri'

module EventsHelper
  include TimeRangeHelper # provides normalize_time

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
end
