require File.dirname(__FILE__) + '/../spec_helper'

describe SourceParser::Hcal, "with hCalendar events" do
  fixtures :events, :venues

  it "should parse hcal" do
    hcal_content = read_sample('hcal_single.xml')
    hcal_source = Source.new(:title => "Calendar event feed", :url => "http://mysample.hcal/")
    SourceParser::Base.should_receive(:read_url).and_return(hcal_content)

    events = hcal_source.to_events

    events.size.should == 1
    for key, value in {
      :title => "Calendar event",
      :description => "Check it out!",
      :start_time => Time.parse("2008-1-19"),
      :end_time => Time.parse("2008-1-20"),
      :url => "http://www.cubespacepdx.com",
      :venue_id => nil, # TODO what should venue instance be?
    }
      events.first.send(key).should == value
    end
  end

  it "should strip html from the venue title" do
    hcal_content = read_sample('hcal_upcoming.xml')
    hcal_source = Source.new(:title => "Calendar event feed", :url => "http://mysample.hcal/")
    SourceParser::Base.stub!(:read_url).and_return(hcal_content)
    events = hcal_source.to_events

    events.first.venue.title.should == 'Jive Software Office'
  end

  it "should parse a page with multiple events" do
    hcal_content = read_sample('hcal_multiple.xml')

    hcal_source = Source.new(:title => "Calendar event feed", :url => "http://mysample.hcal/")
    SourceParser::Base.should_receive(:read_url).and_return(hcal_content)

    events = hcal_source.to_events
    events.size.should == 2
    first, second = *events
    first.start_time.should == Time.parse('2008-1-19')
    first.end_time.should == Time.parse('2008-01-20')
    second.start_time.should == Time.parse('2008-2-2')
    second.end_time.should == Time.parse('2008-02-03')
  end
end

describe SourceParser::Hcal, "with Category" do
  describe "in event" do
    it "should parse a Category in an event"
    it "should parse multiple instances of Category in an event"
    it "should tag events with each parsed Category"
  end

  describe "in hCard" do
    it "should parse a Category in an hCard"
    it "should parse multiple instances of Category in an hCard"
    it "should tag venues with each parsed Category"
  end
end