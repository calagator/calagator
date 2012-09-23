require 'spec_helper'

describe SourceParser::Meetup do
  describe "with a meetup.com API key in secrets.yml" do
    before do
      SECRETS.meetup_api_key = "foo"
    end

    before(:each) do
      content = read_sample('meetup.json')
      HTTParty.should_receive(:get).and_return(MultiJson.decode(content))
      @events = SourceParser::Meetup.to_abstract_events(:url => 'http://www.meetup.com/pdxpython/events/ldhnqyplbnb/')
      @event = @events.first
    end

    it "should find one event" do
      @events.size.should eq 1
    end

    it "should set event details" do
      @event.title.should eq "eLearning Network Meetup"
      @event.start_time.should eq Time.zone.parse("Thu Aug 11 00:00:00 UTC 2011")
    end

    it "should tag Meetup events with automagic machine tags" do
      @event.tags.should eq ["meetup:event=ldhnqyplbnb", "meetup:group=eLearningNetwork"]
    end

    it "should populate a venue when structured data is provided" do
      @event.location.should be_a SourceParser::AbstractLocation
      @event.location.title.should eq "Green Dragon Bistro and Brewpub"
      @event.location.street_address.should eq "928 SE 9th Ave"
      @event.location.tags.should eq ["meetup:venue=774133"]
    end
  end
end
