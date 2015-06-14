require 'spec_helper'

module Calagator

describe Event::Search, :type => :model do
  let(:events) { double }
  before { allow(Event).to receive(:search).and_return(events) }
  before { allow(Event).to receive(:search_tag).and_return(events) }

  let(:search_params) { {} }
  subject(:event_search) { Event::Search.new(search_params) }

  describe "by keyword" do
    let(:search_params) { {query: "myquery"} }

    it "should find all events matching the keyword, ordered by date" do
      event_search.events
      expect(Event).to have_received(:search).with("myquery", skip_old: false, order: "date")
    end

    context "limited to current events" do
      let(:search_params) { {query: "myquery", current: "1"} }

      it "should be able to only return current events" do
        event_search.events
        expect(Event).to have_received(:search).with("myquery", order: "date", skip_old: true)
      end
    end

    context "with an invalid order" do
      let(:search_params) { {query: "myquery", order: "kittens"} }

      it "should set a failure message as a warning" do
        expect(event_search.failure_message).to eq("Unknown ordering option \"kittens\", sorting by date instead.")
      end

      it "should not be a hard failure" do
        expect(event_search).not_to be_hard_failure
      end
    end

    context "when the search encounters an error" do
      before { allow(Event).to receive(:search).and_raise(ActiveRecord::StatementInvalid, "bad times") }
      before { event_search.events }

      it "should set a failure message" do
        expect(event_search.failure_message).to eq("There was an error completing your search.")
      end

      it "should be a hard failure" do
        expect(event_search).to be_hard_failure
      end

      it "should return no events" do
        expect(event_search.events).to be_empty
      end
    end
  end

  describe "by tag" do
    let(:search_params) { {tag: "foo"} }

    it "should find all events matching the tag, ordered by date" do
      event_search.events
      expect(Event).to have_received(:search_tag).with("foo", current: false, order: "date")
    end

    context "with an invalid order" do
      let(:search_params) { {tag: "omg", order: "kittens"} }

      it "should set a failure message as a warning" do
        expect(event_search.failure_message).to eq("Unknown ordering option \"kittens\", sorting by date instead.")
      end

      it "should not be a hard failure" do
        expect(subject).not_to be_hard_failure
      end
    end

    context "attempting to order by score" do
      let(:search_params) { {tag: "omg", order: "score"} }

      it "should set a failure message as a warning" do
        expect(event_search.failure_message).to eq("You cannot sort tags by score")
      end

      it "should not be a hard failure" do
        expect(event_search).not_to be_hard_failure
      end
    end

    context "when the tag search encounters an error" do
      before { allow(Event).to receive(:search_tag).and_raise(ActiveRecord::StatementInvalid.new("bad times")) }
      before { event_search.events }

      it "should set a failure message" do
        expect(event_search.failure_message).to eq("There was an error completing your search.")
      end

      it "should be a hard failure" do
        expect(event_search).to be_hard_failure
      end

      it "should return no events" do
        expect(event_search.events).to be_empty
      end
    end
  end

  describe "#grouped_events" do
    let(:past_event) { double(:event, current?: false) }
    let(:current_event) { double(:event, current?: true) }
    let(:events) { [past_event, current_event] }
    let(:search_params) { {query: "ruby"} }

    it "groups events into a hash by currentness" do
      expect(event_search.grouped_events).to eq({
        past: [past_event],
        current: [current_event],
      })
    end

    context "when passed the 'current' option" do
      let(:search_params) { {query: "ruby", current: "true"} }

      it "discards past events" do
        expect(event_search.grouped_events).to eq({
          past: [],
          current: [current_event],
        })
      end
    end

    context "when passing 'date' to the order option" do
      let(:search_params) { {query: "ruby", order: "date"} }

      let(:other_past_event) { double(:event, current?: false) }
      let(:events) { [current_event, past_event, other_past_event] }

      it "orders past events by date desc" do
        expect(event_search.grouped_events).to eq({
          current: [current_event],
          past:    [past_event, other_past_event],
        })
      end
    end
  end

  describe "hard failures" do
    context "when given neither search query nor tag" do
      let(:search_params) { {} }

      it "should set a failure message" do
        expect(event_search.failure_message).to eq("You must enter a search query")
      end

      it "should be a hard failure" do
        expect(event_search).to be_hard_failure
      end

      it "should return no events" do
        expect(event_search.events).to be_empty
      end
    end

    context "when given both search query and tag" do
      let(:search_params) { {query: "omg", tag: "bbq"} }

      it "should set a failure message" do
        expect(event_search.failure_message).to eq("You can't search by tag and query at the same time")
      end

      it "should be a hard failure" do
        expect(event_search).to be_hard_failure
      end

      it "should return no events" do
        expect(event_search.events).to be_empty
      end
    end
  end
end

end
