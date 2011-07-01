require File.dirname(__FILE__) + '/../spec_helper'

describe SourceParser::Hcal2 do

  before(:each) do
    content = read_sample('hcalendar2.html')
    @events = SourceParser::Hcal2.to_abstract_events(:content => content,
                                                     :url => 'http://microformats.com/fakesample.html',
                                                     :skip_old => false)

    @event = @events.first
  end

  it "should find one event" do
    @events.size.should == 1
  end

  it "should set event details" do
    @event.title.should == "Barcamp Brighton 1"
    @event.start_time.should == Time.parse("Sat, 08 Sep 2007 00:00:00 +0000")
    @event.location.title.should == "Madgex Office, Brighton"
  end

end
