require File.dirname(__FILE__) + '/../spec_helper'

describe SourceParser::Plancast do

  before(:each) do
    content = read_sample('plancast.json')
    HTTParty.should_receive(:get).and_return(Crack::JSON.parse(content))
    @events = SourceParser::Plancast.to_abstract_events(:content => content,
                                                       :url => 'http://plancast.com/p/3cos/indiewebcamp',
                                                       :skip_old => false)
    @event = @events.first
  end

  it "should find one event" do
    @events.size.should == 1
  end

  it "should set event details" do
    @event.title.should == "IndieWebCamp"
    @event.start_time.should == Time.zone.at(1308960000)
  end

  it "should tag Plancast events with automagic machine tags" do
    @event.tags.should == ["plancast:plan=3cos"]
  end

  it "should populate a venue when structured data is provided" do
    @event.location.title.should == "Urban Airship"
    @event.location.address.should == "334 Northwest 11th Avenue, Portland, Oregon, United States"
  end

end
