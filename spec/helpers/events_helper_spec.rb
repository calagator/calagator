require File.dirname(__FILE__) + '/../spec_helper'
include EventsHelper


describe EventsHelper do
  # TODO Do we need a helper to return 'Today' and 'Tomorrow' at all? See app/helpers/events_helper.rb #today_tomorrow_or_weekday
  
=begin
  it "should display today as 'Today'" do
    @event = Event.new
    @event.start_time = Time.now
    helper.today_tomorrow_or_weekday(@event).should == 'Today'
  end
  
  it "should display tomorrow as 'Tomorrow'" do
    @event = Event.new
    @event.start_time = Time.now+1.days
    helper.today_tomorrow_or_weekday(@event).should == 'Tomorrow'
  end
=end
  
end
