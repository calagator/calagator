require 'spec_helper'

module Calagator
  describe Event::Browse do
    describe "when finding by time" do
      before do
        @given_start_time = Time.zone.parse("12:00")
        @given_end_time = Time.zone.parse("17:00")
        @event_before_end_time = FactoryGirl.create(:event,
                                                    start_time: Time.zone.parse("10:00"),
                                                    end_time: Time.zone.parse("14:00"))
        @event_after_start_time = FactoryGirl.create(:event,
                                                     start_time: Time.zone.parse("14:00"),
                                                     end_time: Time.zone.parse("18:00"))
        @event_in_range = FactoryGirl.create(:event,
                                             start_time: Time.zone.parse("13:00"),
                                             end_time: Time.zone.parse("14:00"))
      end

      describe "before time" do
        before do
          @events = Event::Browse.new(time: { end: @given_end_time.strftime('%I:%M %p') }).events
        end

        it "should include events with end_time before given end time" do
          expect(@events).to include(@event_before_end_time, @event_in_range)
        end

        it "should not include events with end_time after given end time" do
          expect(@events).not_to include(@event_after_start_time)
        end
      end

      describe "after time" do
        before do
          @events = Event::Browse.new(time: { start: @given_start_time.strftime('%I:%M %p') }).events
        end

        it "should include events with start_time after given start time" do
          expect(@events).to include(@event_after_start_time, @event_in_range)
        end

        it "should not include events with start_time before given start time" do
          expect(@events).not_to include(@event_before_end_time)
        end
      end

      describe "within time range" do
        before do
          @events = Event::Browse.new(time: {
            start: @given_start_time.strftime('%I:%M %p'),
            end: @given_end_time.strftime('%I:%M %p'),
          }).events
        end

        it "should include events with start_time and end_time between given times" do
          expect(@events).to include(@event_in_range)
        end

        it "should not include events with start_time and end_time not between given times" do
          expect(@events).not_to include(@event_before_end_time)
        end
      end
    end
  end
end
