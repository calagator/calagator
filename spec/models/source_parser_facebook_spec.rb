require 'spec_helper'

describe SourceParser::Facebook do

  before(:each) do
    content = read_sample('facebook.json')
    parsed_content = Crack::JSON.parse(content)
    HTTParty.should_receive(:get).and_return(parsed_content)
    @events = SourceParser::Facebook.to_abstract_events(:url => 'http://facebook.com/event.php?eid=247619485255249')
    @event = @events.first
  end

  it "should find one event" do
    @events.size.should == 1
  end

  it "should set event details" do
    @event.title.should == "Open Source Bridge 2012"
    @event.start_time.should == Time.zone.parse("26 Jun 2012 09:00:00 PDT -07:00")
  end

  it "should tag Facebook events with automagic machine tags" do
    @event.tags.should == ["facebook:event=247619485255249"]
  end

  it "should set the event url to the original import URL" do
    @event.url.should == 'http://facebook.com/event.php?eid=247619485255249'
  end

  it "should populate a venue when structured data is provided" do
    @event.location.title.should          == "Eliot Center"
    @event.location.street_address.should == "1226 SW Salmon Street"
    @event.location.locality.should       == "Portland"
    @event.location.region.should         == "Oregon"
    @event.location.country.should        == "United States"
    @event.location.latitude.to_s.should  == "45.5236"
    @event.location.longitude.to_s.should == "-122.675"
  end

end

