require 'spec_helper'

describe GoogleEventExportHelper, :type => :helper do
  describe "google_event_export_link" do
    def escape(string)
      return Regexp.escape(CGI.escape(string))
    end

    shared_context "exported event setup" do
      before do
        @venue = Venue.create!(:title => "My venue", :address => "1930 SW 4th Ave, Portland, Oregon 97201")
        @event = Event.create!(:title => "My event", :start_time => "2010-01-01 12:00:00", :end_time => "2010-01-01 13:00:00", :venue => @venue, :description => event_description)
        @export = helper.google_event_export_link(@event)
      end
    end

    shared_examples_for "exported event" do
      it "should have title" do
        expect(@export).to match /\&text=#{escape(@event.title)}/
      end

      it "should have time range" do
        expect(@export).to match /\&dates=#{escape("20100101T200000Z/20100101T210000Z")}/
      end

      it "should have venue title" do
        expect(@export).to match /\&location=#{escape(@event.venue.title)}/
      end

      it "should have venue address" do
        expect(@export).to match /\&location=.+?#{escape(@event.venue.geocode_address)}/
      end
    end

    describe "an event's text doesn't need truncation" do
      let(:event_description) { "My event description." }
      include_context "exported event setup"

      it_should_behave_like "exported event"

      it "should have a complete event description" do
        expect(@export).to match /\&details=.*#{escape(event_description)}/
      end
    end

    describe "an event's text needs truncation" do
      let(:event_description) { "My event description. " * 100 }
      include_context "exported event setup"

      it_should_behave_like "exported event"

      it "should have a truncated event description" do
        expect(@export).to match /\&details=.*#{escape(event_description[0..100])}/
      end

      it "should have a truncated URL" do
        expect(@export.size).to be < event_description.size
      end
    end
  end
end
