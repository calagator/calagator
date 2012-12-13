require 'spec_helper'

describe SourceParser::Plancast do

  before(:each) do
    content = read_sample('plancast.json')
    HTTParty.should_receive(:get).and_return(MultiJson.decode(content))
    @events = SourceParser::Plancast.to_abstract_events(:url => 'http://plancast.com/p/3cos/indiewebcamp')
    @event = @events.first
  end

  it "should find one event" do
    @events.size.should eq 1
  end

  it "should set event details" do
    @event.title.should eq "IndieWebCamp"
    @event.start_time.should eq Time.zone.parse("Sat, 25 Jun 2011 00:00:00 PDT -07:00")
  end

  it "should tag Plancast events with automagic machine tags" do
    @event.tags.should eq ["plancast:plan=3cos"]
  end

  it "should populate a venue when structured data is provided" do
    @event.location.title.should eq "Urban Airship"
    @event.location.address.should eq "334 Northwest 11th Avenue, Portland, Oregon, United States"
    @event.location.tags.should eq ["plancast:place=1520153"]
  end

end
