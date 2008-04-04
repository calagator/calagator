require File.dirname(__FILE__) + '/../spec_helper'

describe Source, "when parsing URLs" do
  before(:all) do
    @http_url = 'http://upcoming.yahoo.com/event/390164/'
    @ical_url = 'webcal://upcoming.yahoo.com/event/390164/'
    @base_url = 'upcoming.yahoo.com/event/390164/'
  end

  before(:each) do
    @source = Source.new
  end

  it "should not modify supported url schemes" do
    @source.url = @http_url

    @source.url.should == @http_url
  end

  it "should substitute http for unsupported url schemes" do
    @source.url = @ical_url

    @source.url.should == @http_url
  end

  it "should add the http prefix to urls without one" do
    @source.url = @base_url

    @source.url.should == @http_url
  end
end

describe Source, "with hCalendar events" do
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
      :url => "http://www.cubespacepdx.com",
      :venue => nil, # TODO what should venue instance be?
    }
      events.first[key].should == value
    end
  end

  it "should parse a page with more than one hcal item in it" do
    hcal_content = read_sample('hcal_multiple.xml')

    hcal_source = Source.new(:title => "Calendar event feed", :url => "http://mysample.hcal/")
    SourceParser::Base.should_receive(:read_url).and_return(hcal_content)

    events = hcal_source.to_events
    events.size.should == 2
    first, second = *events
    first[:start_time ].should == Time.parse('2008-1-19')
    second[:start_time].should == Time.parse('2008-2-2')
  end
end

describe Source, "with iCalendar events" do
  def events_from_ical_at(filename)
    url = "http://foo.bar/"
    source = Source.new(:title => "Calendar event feed", :url => url)
    SourceParser::Base.should_receive(:read_url).and_return(read_sample(filename))
    return source.to_events
  end

  it "should parse Apple iCalendar format" do
    events = events_from_ical_at('ical_apple.ics')

    events.size.should == 1
    event = events.first
    event.title.should =~ /Coffee with Jason/
    event.start_time.should == Time.parse('Mon Oct 28 14:00:00 -0800 2002')
    event.venue.should be_nil
  end

  it "should parse basic iCalendar format" do
    events = events_from_ical_at('ical_basic.ics')

    events.size.should == 1
    event = events.first
    event.title.should be_blank
    event.start_time.should == Time.parse('Wed Jan 17 00:00:00 UTC 2007')
    event.venue.should be_nil
  end

  it "should parse Upcoming iCalendar format and associate the event with a venue" do
    events = events_from_ical_at('ical_upcoming.ics')
    events.size.should == 1
    event = events.first
    event.title.should =~ /Ignite Portland/
    event.start_time.should == Time.parse('Tue Feb 05 18:00:00 -0800 2008')
    event.description.should =~ /What if you only got 20 slides/
    event.venue.should_not be_blank
    event.venue.title.should =~ /Bagdad Theater/
    event.venue.locality.should =~ /Portland/
    event.venue.country.should =~ /United States/
    event.venue.postal_code.should =~ /97214/
    event.venue.latitude.should == BigDecimal.new("45.5121")
    event.venue.longitude.should == BigDecimal.new("-122.626")
  end

  it "should parse Google iCalendar feed with multiple events" do
    events = events_from_ical_at('ical_google.ics')

    events.size.should == 47

    event = events.first
    event.title.should == "XPDX (eXtreme Programming) at CubeSpace"
    event.description.should be_blank
    event.start_time.should == Time.parse("2007-10-24 18:30:00")

    event = events[17]
    event.title.should == "Code Sprint/Coding Dojo at CubeSpace"
    event.description.should be_blank
    event.start_time.should == Time.parse("2007-10-17 19:00:00")

    event = events.last
    event.title.should == "Adobe Developer User Group"
    event.description.should == "http://pdxria.com/"
    event.start_time.should == Time.parse("2007-01-16 17:30:00")
  end

  it "should parse non-Vcard locations" do
    events = events_from_ical_at('ical_google.ics')
    events.first.venue.title.should == 'CubeSpace'
  end
end
