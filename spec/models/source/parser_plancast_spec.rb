require 'spec_helper'

describe Source::Parser::Plancast, :type => :model do

  context do
    before(:each) do
      plancast_url = 'http://plancast.com/p/3cos/indiewebcamp'
      api_url = 'http://api.plancast.com/02/plans/show.json?extensions=place&plan_id=3cos'
      stub_request(:get, api_url).to_return(body: read_sample('plancast.json'), headers: { content_type: "application/json" })

      @events = Source::Parser::Plancast.to_events(url: plancast_url)
      @event = @events.first
    end

    it "should find one event" do
      expect(@events.size).to eq 1
    end

    it "should set event details" do
      expect(@event.title).to eq "IndieWebCamp"
      expect(@event.start_time).to eq Time.zone.parse("Sat, 25 Jun 2011 00:00:00 PDT -07:00")
    end

    it "should tag Plancast events with automagic machine tags" do
      expect(@event.tag_list).to eq ["plancast:plan=3cos"]
    end

    it "should populate a venue when structured data is provided" do
      expect(@event.venue.title).to eq "Urban Airship"
      expect(@event.venue.address).to eq "334 Northwest 11th Avenue, Portland, Oregon, United States"
      expect(@event.venue.tag_list).to eq ["plancast:place=1520153"]
    end
  end

  context "with missing venue" do
    before(:each) do
      plancast_url = 'http://plancast.com/p/3cos/indiewebcamp'
      api_url = 'http://api.plancast.com/02/plans/show.json?extensions=place&plan_id=3cos'
      stub_request(:get, api_url).to_return(body: read_sample('plancast_with_missing_venue.json'), headers: { content_type: "application/json" })
      @events = Source::Parser::Plancast.to_events(url: plancast_url)
      @event = @events.first
    end

    it "uses fallback when no venue is detected" do
      expect(@event.venue.title).to eq "The Center of the Earth"
      expect(@event.venue.address).to be_blank
    end
  end
end
