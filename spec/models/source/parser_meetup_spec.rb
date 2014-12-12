require 'spec_helper'

describe Source::Parser::Meetup, :type => :model do
  describe "with a meetup.com API key in secrets.yml" do
    before do
      SECRETS.meetup_api_key = "foo"
    end

    before(:each) do
      meetup_url = "http://www.meetup.com/pdxpython/events/ldhnqyplbnb/"
      api_url = "https://api.meetup.com/2/event/ldhnqyplbnb?key=foo&sign=true"

      stub_request(:get, api_url).to_return(body: read_sample('meetup.json'), headers: { content_type: "application/json" })
      @events = Source::Parser::Meetup.to_events(url: meetup_url)
      @event = @events.first
    end

    it "should find one event" do
      expect(@events.size).to eq 1
    end

    it "should set event details" do
      expect(@event.title).to eq "eLearning Network Meetup"
      expect(@event.start_time).to eq Time.zone.parse("Thu Aug 11 00:00:00 UTC 2011")
    end

    it "should tag Meetup events with automagic machine tags" do
      expect(@event.tag_list).to eq ["meetup:event=ldhnqyplbnb", "meetup:group=eLearningNetwork"]
    end

    it "should populate a venue when structured data is provided" do
      expect(@event.venue).to be_a Venue
      expect(@event.venue.title).to eq "Green Dragon Bistro and Brewpub"
      expect(@event.venue.street_address).to eq "928 SE 9th Ave"
      expect(@event.venue.tag_list).to eq ["meetup:venue=774133"]
    end
  end

  context "without a meetup API key" do
    before do
      SECRETS.meetup_api_key = nil
    end

    before(:each) do
      url = "http://www.meetup.com/pdxpython/events/ldhnqyplbnb/ical"
      stub_request(:get, url).to_return(body: read_sample('meetup.ics'))
      @events = Source::Parser::Meetup.to_events(url: url)
      @event = @events.first
    end

    it "should find one event" do
      expect(@events.size).to eq 1
    end

    it "should set event details" do
      expect(@event.title).to eq "eLearning Network Meetup"
      expect(@event.start_time.to_s).to eq "3011-08-10 23:00:00 -0800"
    end

    it "should populate a venue when structured data is provided" do
      expect(@event.venue).to be_a Venue
      expect(@event.venue.title).to eq "Green Dragon Bistro and Brewpub"
    end
  end
end
