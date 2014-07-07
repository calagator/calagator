require 'spec_helper'

describe Event::Search do
  describe "by keyword" do
    it "should be able to only return events that include a specific keyword" do
      grouped_events = double(:grouped_events)
      Event.should_receive(:search_keywords_grouped_by_currentness)
        .with("myquery", skip_old: false, order: nil).and_return(grouped_events)

      subject = Event::Search.new query: "myquery"
      subject.grouped_events.should == grouped_events
    end

    it "should be able to only return current events" do
      grouped_events = double(:grouped_events)
      Event.should_receive(:search_keywords_grouped_by_currentness)
        .with("myquery", order: nil, skip_old: true).and_return(grouped_events)

      subject = Event::Search.new query: "myquery", current: "1"
      subject.grouped_events.should == grouped_events
    end

    it "should warn if user tries ordering by invalid order" do
      subject = Event::Search.new query: "myquery", order: "kittens"
      subject.failure_message.should == "Unknown ordering option \"kittens\", sorting by date instead."
      subject.should_not be_hard_failure
    end
  end

  describe "by tag" do
    it "should be able to only return events matching specific tag" do
      grouped_events = double(:grouped_events)
      Event.should_receive(:search_tag_grouped_by_currentness)
        .with("foo", current: false, order: nil).and_return(grouped_events)

      subject = Event::Search.new tag: "foo"
      subject.grouped_events.should == grouped_events
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
end
