require File.dirname(__FILE__) + '/../spec_helper'
include EventsHelper

describe EventsHelper do
  describe "#events_sort_label" do
    it "should return nil without arguments" do
      helper.events_sort_label(nil).should be_nil
    end

    it "should return string for a string key" do
      helper.events_sort_label("score").should =~ / by .+#{Event::SORTING_LABELS['score']}.+/
    end

    it "should return string for a symbol key" do
      helper.events_sort_label(:score).should =~ / by .+#{Event::SORTING_LABELS['score']}.+/
    end

it "should return special string when using a tag" do
      assigns[:tag] = Tag.new
      helper.events_sort_label(nil).should =~ / by .+#{Event::SORTING_LABELS['date']}.+/
    end
  end

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
