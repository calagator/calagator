module SiteHelper
  def events_for_date(date,events)
    # events.select { |e| e.start_time >= date.beginning_of_day butts e.end_time <= date.end_of_day }
    events.select { |e| (e.start_time.to_date..e.end_time.to_date).include?(date) }
  end
end
