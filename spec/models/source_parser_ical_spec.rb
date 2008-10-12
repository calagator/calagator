require File.dirname(__FILE__) + '/../spec_helper'

describe SourceParser::Ical, "in general" do
  it "should read http URLs as-is" do
    http_url = "http://foo.bar/"
    stub_source_parser_http_response!(:body => 42)

    SourceParser::Ical.read_url(http_url).should == 42
  end

  it "should read webcal URLs as http" do
    webcal_url = "webcal://foo.bar/"
    http_url   = "http://foo.bar/"
    stub_source_parser_http_response!(:body => 42)
    SourceParser::Ical.read_url(webcal_url).should == 42
  end
end

describe SourceParser::Ical, "when parsing locations" do
  it "should fallback on VPIM errors" do
    invalid_hcard = <<-HERE
BEGIN:VVENUE
omgwtfbbq
END:VVENUE
    HERE

    SourceParser::Ical.to_abstract_location(invalid_hcard, :fallback => "mytitle").title.should == "mytitle"
  end
end

describe SourceParser::Ical, "when parsing multiple items in an Upcoming feed" do
  before(:all) do
    SourceParser::Base.should_receive(:read_url).and_return(read_sample('ical_upcoming_many.ics'))
    @events = SourceParser.to_abstract_events(:url => "intercepted", :skip_old => false)
  end

  it "should find multiple events" do
    @events.size.should == 20
  end

  it "should find venues for events" do
    @events.each do |event|
      event.location.title.should_not be_nil
    end
  end

  it "should match each event with its venue" do
    event_titles_and_street_addresses = [
      ["Substance Summit", "1945 NW Quimby"],
      ["Mobile Love, Android Style #4", "915 SE Hawthorne Boulevard"],
      ["SEMpdx Networking Event", "65 SW Yamhill St."],
    ]

    # Make sure each of the above events has the expected street address
    event_titles_and_street_addresses.each do |event_title, street_address|
      @events.find{|event|
        event.title == event_title && event.location.street_address == street_address
      }.should_not be_nil
    end
  end
end

describe SourceParser::Ical, "when parsing multiple items in an Eventful feed" do
  before(:all) do
    SourceParser::Base.should_receive(:read_url).and_return(read_sample('ical_eventful_many.ics'))
    @events = SourceParser.to_abstract_events(:url => "intercepted", :skip_old => false)
  end

  it "should find multiple events" do
    @events.size.should == 15
  end

  it "should find venues for events" do
    @events.each do |event|
      event.location.title.should_not be_nil
    end
  end

  it "should match each event with its venue" do
    event_titles_and_street_addresses = [
      ["iMovie and iDVD Workshop", "7293 SW Bridgeport Road"],
      ["Portland Macintosh Users Group (PMUG)", "Jean Vollum Natural Capital Center"],
      ["Morning Meetings: IT", "622 SE Grand Avenue"],
    ]

    # Make sure each of the above events has the expected street address
    event_titles_and_street_addresses.each do |event_title, street_address|
      @events.find{|event|
        event.title == event_title && event.location.street_address == street_address
      }.should_not be_nil
    end
  end
end
describe SourceParser::Ical, "with iCalendar events" do
  def events_from_ical_at(filename)
    url = "http://foo.bar/"
    source = Source.new(:title => "Calendar event feed", :url => url)
    SourceParser::Base.should_receive(:read_url).and_return(read_sample(filename))
    return source.to_events(:skip_old => false)
  end

  it "should parse Apple iCalendar format" do
    events = events_from_ical_at('ical_apple.ics')

    events.size.should == 1
    event = events.first
    event.title.should == "Coffee with Jason"
    event.start_time.should == Time.parse('Thu Nov 28 14:00:00 -0800 2002')
    event.end_time.should == Time.parse('Thu Nov 28 15:00:00 -0800 2002')
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

    event.title.should == "Ignite Portland"
    event.start_time.should == Time.parse('Tue Feb 05 18:00:00 -0800 2008')
    event.end_time.should == Time.parse('Tue Feb 05 21:00:00 -0800 2008')
    event.description.should == "[Full details at http://upcoming.yahoo.com/event/390164/ ] If you had five minutes to talk to Portland what would you say? What if you only got 20 slides and they rotated automatically after 15 seconds? Launch a web site? Teach a hack? Talk about recent learnings, successes, failures?          Come join us for the second Ignite Portland! It's free to attend or present. We hope to have food and drinks, but we need sponsors for that, so check out http://www.igniteportland.com for details on attending, presenting, or sponsoring!          What is Ignite Portland? A bunch of fast-paced, interesting presentations - 20 slides for 15 seconds each. Our mantra is \"share burning ideas\" - just about any topic will do, as long as it's interesting. From tech to crafts to business to just plain fun! There will be time to network and chat after each series of presentations."

    event.venue.should_not be_blank
    event.venue.title.should == "Bagdad Theater and Pub"
    event.venue.locality.should == "Portland"
    event.venue.country.should == "United States"
    event.venue.postal_code.should == "97214"
    event.venue.latitude.should == BigDecimal.new("45.5121")
    event.venue.longitude.should == BigDecimal.new("-122.626")
  end

  it "should parse Google iCalendar feed with multiple events" do
    events = events_from_ical_at('ical_google.ics')
    # TODO add specs for venues/locations

    events.size.should == 47

    event = events.first
    event.title.should == "XPDX (eXtreme Programming) at CubeSpace"
    event.description.should be_blank
    event.start_time.should == Time.parse("2007-10-24 18:30:00")
    event.end_time.should == Time.parse('Wed Oct 24 19:30:00 -0700 2007')

    event = events[17]
    event.title.should == "Code Sprint/Coding Dojo at CubeSpace"
    event.description.should be_blank
    event.start_time.should == Time.parse("2007-10-17 19:00:00")
    event.end_time.should == Time.parse('Wed Oct 17 21:00:00 -0700 2007')

    event = events.last
    event.title.should == "Adobe Developer User Group"
    event.description.should == "http://pdxria.com/"
    event.start_time.should == Time.parse("2007-01-16 17:30:00")
    event.end_time.should == Time.parse("Tue Jan 16 18:30:00 -0800 2007")
  end

  it "should parse non-Vcard locations" do
    events = events_from_ical_at('ical_google.ics')
    events.first.venue.title.should == 'CubeSpace'
  end

end

describe SourceParser::Ical, "when importing events with non-local times" do

  it "should store time ending in Z as UTC" do
    url = "http://foo.bar/"
    SourceParser::Base.stub!(:read_url).and_return(read_sample('ical_z.ics'))
    @source = Source.new(:title => "Non-local time", :url => url)
    events = @source.create_events!(:skip_old => false)
    event = events.first

    event.start_time.should == Time.parse('Thu Jul 01 08:00:00 +0000 2010')
    event.end_time.should == Time.parse('Thu Jul 01 09:00:00 +0000 2010')

    # time should be the same after saving event to, and getting it from, database
    event.save
    e = Event.find(event)
    e.start_time.should == Time.parse('Thu Jul 01 08:00:00 +0000 2010')
    e.end_time.should == Time.parse('Thu Jul 01 09:00:00 +0000 2010')

end

  it "should store time with TZID=GMT in UTC" do
    pending "not activated - requires VPIM fix or work-around. See Issue238."
    events = events_from_ical_at('ical_gmt.ics')
    events.size.should == 1
    abstract_event = events.first
    abstract_event.start_time.should == Time.parse('Fri May 07 08:00:00 +0000 2020')
    abstract_event.end_time.should == Time.parse('Fri May 07 09:00:00 +0000 2020')
  end

end

describe SourceParser::Ical, "when skipping old events" do
  before(:each) do
    SourceParser::Base.stub!(:read_url).and_return(<<-HERE)
BEGIN:VCALENDAR
X-WR-CALNAME;VALUE=TEXT:NERV
VERSION:2.0
CALSCALE:GREGORIAN
PRODID:-//nerv.go.jp//iCal 1.0//EN
X-WR-TIMEZONE;VALUE=TEXT:US/Eastern
BEGIN:VEVENT
UID:Unit-01
SUMMARY:Past start and no end
DESCRIPTION:Ayanami
DTSTART:#{(Time.now-1.year).strftime("%Y%m%d")}
DTSTAMP:040425
SEQ:0
END:VEVENT
BEGIN:VEVENT
UID:Unit-02
SUMMARY:Current start and no end
DESCRIPTION:Soryu
DTSTART:#{(Time.now+1.year).strftime("%Y%m%d")}
DTSTAMP:040425
SEQ:1
END:VEVENT
BEGIN:VEVENT
UID:Unit-03
SUMMARY:Past start and current end
DESCRIPTION:Soryu a
DTSTART:#{(Time.now-1.year).strftime("%Y%m%d")}
DTEND:#{(Time.now+1.year).strftime("%Y%m%d")}
DTSTAMP:040425
END:VEVENT
BEGIN:VEVENT
UID:Unit-04
SUMMARY:Current start and current end
DESCRIPTION:Soryu as
DTSTART:#{Time.now.strftime("%Y%m%d")}
DTEND:#{(Time.now+1.year).strftime("%Y%m%d")}
DTSTAMP:040425
END:VEVENT
BEGIN:VEVENT
UID:Unit-05
SUMMARY:Past start and past end
DESCRIPTION:Soryu qewr
DTSTART:#{(Time.now-1.year).strftime("%Y%m%d")}
DTEND:#{(Time.now-1.year).strftime("%Y%m%d")}
DTSTAMP:040425
END:VEVENT
BEGIN:VEVENT
UID:Unit-06
SUMMARY:Current start and past end
DESCRIPTION:Not a valid event
DTSTART:#{Time.now.strftime("%Y%m%d")}
DTEND:#{(Time.now-1.year).strftime("%Y%m%d")}
DTSTAMP:040425
END:VEVENT
END:VCALENDAR
      HERE
    @source = Source.new(:title => "Title", :url => "http://my.url/")
  end

  # for following specs a 'valid' event does not start after it ends"
  it "should be able to import all valid events" do
    events = @source.create_events!(:skip_old => false)
    events.size.should == 5
    events.map(&:title).should == [
      "Past start and no end",
      "Current start and no end",
      "Past start and current end",
      "Current start and current end",
      "Past start and past end"
    ]
  end

  it "should be able to skip invalid and old events" do
    events = @source.create_events!(:skip_old => true)
    events.size.should == 3
    events.map(&:title).should == [
      "Current start and no end",
      "Past start and current end",
      "Current start and current end"
    ]
  end

end
