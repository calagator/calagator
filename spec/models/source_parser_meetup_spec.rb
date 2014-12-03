require 'spec_helper'

describe SourceParser::Meetup, :type => :model do
  describe "with a meetup.com API key in secrets.yml" do
    before do
      SECRETS.meetup_api_key = "foo"
    end

    before(:each) do
      content = read_sample('meetup.json')
      expect(HTTParty).to receive(:get).and_return(MultiJson.decode(content))
      @events = SourceParser::Meetup.to_abstract_events(:url => 'http://www.meetup.com/pdxpython/events/ldhnqyplbnb/')
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
      expect(@event.tags).to eq ["meetup:event=ldhnqyplbnb", "meetup:group=eLearningNetwork"]
    end

    it "should populate a venue when structured data is provided" do
      expect(@event.location).to be_a SourceParser::AbstractLocation
      expect(@event.location.title).to eq "Green Dragon Bistro and Brewpub"
      expect(@event.location.street_address).to eq "928 SE 9th Ave"
      expect(@event.location.tags).to eq ["meetup:venue=774133"]
    end
  end
end
