require 'spec_helper'

describe Event::Search do
  describe "by keyword" do
    it "should be able to only return events that include a specific keyword" do
      events = double
      Event.should_receive(:search).with("myquery", skip_old: false, order: "date").and_return(events)

      subject = Event::Search.new query: "myquery"
      subject.events.should == events
    end

    it "should be able to only return current events" do
      events = double
      Event.should_receive(:search).with("myquery", order: "date", skip_old: true).and_return(events)

      subject = Event::Search.new query: "myquery", current: "1"
      subject.events.should == events
    end

    it "should warn if user tries ordering by invalid order" do
      subject = Event::Search.new query: "myquery", order: "kittens"
      subject.failure_message.should == "Unknown ordering option \"kittens\", sorting by date instead."
      subject.should_not be_hard_failure
    end
  end

  describe "by tag" do
    it "should be able to only return events matching specific tag" do
      events = double
      Event.should_receive(:search_tag).with("foo", current: false, order: "date").and_return(events)

      subject = Event::Search.new tag: "foo"
      subject.events.should == events
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

  describe "#grouped_events" do
    it "groups events into a hash by currentness" do
      past_event = double(:event, current?: false)
      current_event = double(:event, current?: true)
      events = [past_event, current_event]
      Event.should_receive(:search).and_return(events)

      subject.grouped_events.should == {
        past: [past_event],
        current: [current_event],
      }
    end

    it "discards past events when passed the current option" do
      past_event = double(:event, current?: false)
      current_event = double(:event, current?: true)
      events = [past_event, current_event]
      Event.should_receive(:search).and_return(events)

      subject = Event::Search.new(current: "true").grouped_events.should == {
        past: [],
        current: [current_event],
      }
    end

    it "orders past events by date desc if passed date to the order option" do
      current_event = double(:event, current?: true)
      past_event = double(:event, current?: false)
      other_past_event = double(:event, current?: false)
      Event.should_receive(:search).and_return([current_event, past_event, other_past_event])
      Event::Search.new(order: "date").grouped_events.should eq({
        current: [current_event],
        past:    [past_event, other_past_event],
      })
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
end

