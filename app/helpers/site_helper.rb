module SiteHelper
  def events_for_date(date,events)
    events.select do |e|
      if e.end_time
        (e.start_time.to_date..e.end_time.to_date).include?(date)
      else
        e.start_time.to_date == date
      end
    end
  end

  def events_this_month?(date=nil, events=nil)
    date ||= @date
    events ||= @events
    month_start = date.beginning_of_month
    month_end   = date.end_of_month
    events.any? do |e|
      e.start_time.to_date > month_start && e.start_time.to_date < month_end
    end
  end
end
