require 'spec_helper'

describe Event::Overview do
  describe "#times_to_events" do
    before do
      @today_midnight = today
      @yesterday = @today_midnight.yesterday
      @tomorrow = @today_midnight.tomorrow

      @this_venue = Venue.create!(:title => "This venue")

      @started_before_today_and_ends_after_today = Event.create!(
        :title => "Event in progress",
        :start_time => @yesterday,
        :end_time => @tomorrow,
        :venue_id => @this_venue.id)

      @started_midnight_and_continuing_after = Event.create!(
        :title => "Midnight start",
        :start_time => @today_midnight,
        :end_time => @tomorrow,
        :venue_id => @this_venue.id)

      @started_and_ended_yesterday = Event.create!(
        :title => "Yesterday start",
        :start_time => @yesterday,
        :end_time => @yesterday.end_of_day,
        :venue_id => @this_venue.id)

      @started_today_and_no_end_time = Event.create!(
        :title => "nil end time",
        :start_time => @today_midnight,
        :end_time => nil,
        :venue_id => @this_venue.id)

      @starts_and_ends_tomorrow = Event.create!(
        :title => "starts and ends tomorrow",
        :start_time => @tomorrow,
        :end_time => @tomorrow.end_of_day,
        :venue_id => @this_venue.id)

      @starts_after_tomorrow = Event.create!(
        :title => "Starting after tomorrow",
        :start_time => @tomorrow + 1.day,
        :venue_id => @this_venue.id)

      @started_before_today_and_ends_at_midnight = Event.create!(
        :title => "Midnight end",
        :start_time => @yesterday,
        :end_time => @today_midnight,
        :venue_id => @this_venue.id)

      @future_events_for_this_venue = @this_venue.events.future
    end

    describe "events today" do
      it "should include events that started before today and end after today" do
        subject.today.should include @started_before_today_and_ends_after_today
      end

      it "should include events that started earlier today" do
        subject.today.should include @started_midnight_and_continuing_after
      end

      it "should not include events that ended before today" do
        subject.today.should_not include @started_and_ended_yesterday
      end

      it "should not include events that start tomorrow" do
        subject.today.should_not include @starts_and_ends_tomorrow
      end

      it "should not include events that ended at midnight today" do
        subject.today.should_not include @started_before_today_and_ends_at_midnight
      end
    end

    describe "events tomorrow" do
      it "should not include events that start after tomorrow" do
        subject.tomorrow.should_not include @starts_after_tomorrow
      end
    end

    describe "determining if we should show the more link" do
      it "should provide :more item if there are events past the future cutoff" do
        event = stub_model(Event)
        Event.should_receive(:after_date).with(today + 2.weeks).and_return([event])

        subject.more.should eq event
      end

      it "should set :more item if there are no events past the future cutoff" do
        event = stub_model(Event)
        Event.should_receive(:after_date).with(today + 2.weeks).and_return([])

        subject.more.should be_blank
      end
    end
  end
end

