require 'spec_helper'

describe Event::Overview, :type => :model do
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
        expect(subject.today).to include event
      end

      it "should include events that started earlier today" do
        event = FactoryGirl.create(:event, start_time: @today_midnight)
        expect(subject.today).to include event
      end

      it "should not include events that ended before today" do
        event = FactoryGirl.create(:event, start_time: @yesterday, end_time: @yesterday.end_of_day)
        expect(subject.today).not_to include event
      end

      it "should not include events that start tomorrow" do
        event = FactoryGirl.create(:event, start_time: @tomorrow)
        expect(subject.today).not_to include event
      end

      it "should not include events that ended at midnight today" do
        event = FactoryGirl.create(:event, start_time: @yesterday, end_time: @today_midnight)
        expect(subject.today).not_to include event
      end
    end

    describe "#tomorrow" do
      it "should include events that start tomorrow" do
        event = FactoryGirl.create(:event, start_time: @tomorrow)
        expect(subject.tomorrow).to include event
      end

      it "should not include events that start after tomorrow" do
        event = FactoryGirl.create(:event, start_time: @day_after_tomorrow)
        expect(subject.tomorrow).not_to include event
      end
    end

    describe "#later" do
      it "should include events that start after tomorrow" do
        event = FactoryGirl.create(:event, start_time: @day_after_tomorrow)
        expect(subject.later).to include event
      end

      it "should not include events that start after two weeks" do
        event = FactoryGirl.create(:event, start_time: 2.weeks.from_now)
        expect(subject.later).not_to include event
      end
    end

    describe "#more" do
      it "should provide an event if there are events past the future cutoff" do
        event = FactoryGirl.create(:event, start_time: 2.weeks.from_now)
        expect(subject.more).to eq(event)
      end

      it "should be nil if there are no events past the future cutoff" do
        event = FactoryGirl.create(:event, start_time: 2.weeks.from_now - 1.day)
        expect(subject.more).to be_blank
      end
    end
  end
end

