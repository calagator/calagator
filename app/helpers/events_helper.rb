require 'uri'

module EventsHelper
  def url_column(record)
    begin
      link = URI.parse(record.url)
      raise "Invalid url" unless link.scheme =~ /^https?$/
      link_to("Link", link.to_s)
    rescue
      nil
    end
  end

  def to_hcal_column(record)
    record.to_hcal
  end
  
  def today_tomorrow_or_weekday(record)
    if record.start_time.strftime('%Y:%j') == Time.today.strftime('%Y:%j')
      'Today'
    elsif record.start_time.strftime('%Y:%j') == (Time.today+1.day).strftime('%Y:%j')
      'Tomorrow'
    else
      record.start_time.strftime('%A')
    end
  end
  
  def normalize_minutes()
  end
  

end
