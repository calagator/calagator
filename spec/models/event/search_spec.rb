require 'spec_helper'

describe Event::Search do
  describe "by keyword" do
    it "should be able to only return events that include a specific keyword" do
      past_event = double(:event, current?: false)
      current_event = double(:event, current?: true)
      events = [past_event, current_event]
      Event.should_receive(:search).with("myquery", skip_old: false, order: nil).and_return(events)

      subject = Event::Search.new query: "myquery"
      subject.grouped_events.should == {
        past: [past_event],
        current: [current_event],
      }
    end

    xit "should be able to only return current events" do
      past_event = double(:event, current?: false)
      current_event = double(:event, current?: true)
      events = [past_event, current_event]
      Event.should_receive(:search).with("myquery", order: nil, skip_old: true).and_return(events)

      subject = Event::Search.new query: "myquery", current: "1"
      subject.grouped_events.should == {
        past: [],
        current: [current_event],
      }
    end

    it "should warn if user tries ordering by invalid order" do
      subject = Event::Search.new query: "myquery", order: "kittens"
      subject.failure_message.should == "Unknown ordering option \"kittens\", sorting by date instead."
      subject.should_not be_hard_failure
    end
  end

  describe "by tag" do
    it "should be able to only return events matching specific tag" do
      past_event = double(:event, current?: false)
      current_event = double(:event, current?: true)
      events = [past_event, current_event]
      Event.should_receive(:search_tag).with("foo", current: false, order: nil).and_return(events)

      subject = Event::Search.new tag: "foo"
      subject.grouped_events.should == {
        past: [past_event],
        current: [current_event],
      }
    end

    it "should warn if user tries ordering by invalid order" do
      subject = Event::Search.new tag: "omg", order: "kittens"
      subject.failure_message.should == "Unknown ordering option \"kittens\", sorting by date instead."
      subject.should_not be_hard_failure
    end

    it "should warn if user tries ordering tags by score" do
      subject = Event::Search.new tag: "omg", order: "score"
      subject.failure_message.should == "You cannot sort tags by score"
      subject.should_not be_hard_failure
    end
  end

  describe "hard failures" do
    it "should hard fail if given no search query" do
      subject.failure_message.should == "You must enter a search query"
      subject.should be_hard_failure
    end

    it "should hard fail if searching by both query and tag" do
      subject = Event::Search.new query: "omg", tag: "bbq"
      subject.failure_message.should == "You can't search by tag and query at the same time"
      subject.should be_hard_failure
    end
  end

  describe "when searching" do
    describe "with .search_tag_grouped_by_currentness" do
      before do
        @untagged_current_event = FactoryGirl.create(:event, tag_list: ["no"], start_time: Time.now)
        @current_event = FactoryGirl.create(:event, tag_list: ["no", "yes"], start_time: Time.now)
        @past_event = FactoryGirl.create(:event, tag_list: ["yes", "no"], start_time: 1.year.ago)
        @untagged_past_event = FactoryGirl.create(:event, tag_list: ["no"], start_time: 1.year.ago)
      end

      it "should find events by tag and group them" do
        Event::Search.new(query: "yes").grouped_events.should eq({
          current: [@current_event],
          past:    [@past_event],
        })
      end

      it "discards past event if passed the current option" do
        Event::Search.new(query: "yes", current: "true").grouped_events.should eq({
          current: [@current_event],
          past:    [],
        })
      end
    end

    describe "with .search_keywords_grouped_by_currentness" do
      before do
        @current_event = mock_model(Event, :current? => true, :duplicate_of_id => nil)
        @past_event = mock_model(Event, :current? => false, :duplicate_of_id => nil)
        @other_past_event = mock_model(Event, :current? => false, :duplicate_of_id => nil)
      end

      it "should find events and group them" do
        Event.should_receive(:search).with("query", order: nil, skip_old: false)
          .and_return([@current_event, @past_event, @other_past_event])
        Event::Search.new(query: "query").grouped_events.should eq({
          current: [@current_event],
          past:    [@past_event, @other_past_event],
        })
      end

      it "orders past events by date desc if passed date to the order option" do
        Event.should_receive(:search).with("query", order: "date", skip_old: false)
          .and_return([@current_event, @past_event, @other_past_event])
        Event::Search.new(query: "query", order: "date").grouped_events.should eq({
          current: [@current_event],
          past:    [@other_past_event, @past_event],
        })
      end
    end
  end

end
