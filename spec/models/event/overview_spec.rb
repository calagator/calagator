require 'spec_helper'

describe Event::Overview do
  describe "#times_to_events" do
    before do
      @today_midnight = today
      @yesterday = @today_midnight.yesterday
      @tomorrow = @today_midnight.tomorrow
      @day_after_tomorrow = @tomorrow.tomorrow
    end

    describe "#today" do
      it "should include events that started before today and end after today" do
        event = FactoryGirl.create(:event, start_time: @yesterday, end_time: @tomorrow)
        subject.today.should include event
      end

      it "should include events that started earlier today" do
        event = FactoryGirl.create(:event, start_time: @today_midnight)
        subject.today.should include event
      end

      it "should not include events that ended before today" do
        event = FactoryGirl.create(:event, start_time: @yesterday, end_time: @yesterday.end_of_day)
        subject.today.should_not include event
      end

      it "should not include events that start tomorrow" do
        event = FactoryGirl.create(:event, start_time: @tomorrow)
        subject.today.should_not include event
      end

      it "should not include events that ended at midnight today" do
        event = FactoryGirl.create(:event, start_time: @yesterday, end_time: @today_midnight)
        subject.today.should_not include event
      end
    end

    describe "#tomorrow" do
      it "should include events that start tomorrow" do
        event = FactoryGirl.create(:event, start_time: @tomorrow)
        subject.tomorrow.should include event
      end

      it "should not include events that start after tomorrow" do
        event = FactoryGirl.create(:event, start_time: @day_after_tomorrow)
        subject.tomorrow.should_not include event
      end
    end

    describe "#later" do
      it "should include events that start after tomorrow" do
        event = FactoryGirl.create(:event, start_time: @day_after_tomorrow)
        subject.later.should include event
      end

      it "should not include events that start after two weeks" do
        event = FactoryGirl.create(:event, start_time: 2.weeks.from_now)
        subject.later.should_not include event
      end
    end

    describe "#more" do
      it "should provide an event if there are events past the future cutoff" do
        event = FactoryGirl.create(:event, start_time: 2.weeks.from_now)
        subject.more.should == event
      end

      it "should be nil if there are no events past the future cutoff" do
        event = FactoryGirl.create(:event, start_time: 2.weeks.from_now - 1.day)
        subject.more.should be_blank
      end
    end
  end
end

