require 'spec_helper'

def events_from_ical_at(filename)
  url = "http://foo.bar/"
  source = Source.new(:title => "Calendar event feed", :url => url)
  stub_request(:get, url).to_return(body: read_sample(filename))
  return source.to_events(:skip_old => false)
end

describe Source::Parser::Ical, "in general", :type => :model do
  it "should read http URLs as-is" do
    url = "http://foo.bar/"
    stub_request(:get, url).to_return(body: "42")
    expect(Source::Parser::Ical.read_url(url)).to eq "42"
  end

  it "should read webcal URLs as http" do
    webcal_url = "webcal://foo.bar/"
    http_url   = "http://foo.bar/"
    stub_request(:get, http_url).to_return(body: "42")
    expect(Source::Parser::Ical.read_url(webcal_url)).to eq "42"
  end
end

describe Source::Parser::Ical, "when parsing events and their venues", :type => :model do

  before(:each) do
    url = "http://foo.bar/"
    stub_request(:get, url).to_return(body: read_sample('ical_upcoming_many.ics'))
    @events = Source::Parser.to_events(url: url, skip_old: false)
  end

   it "venues should be" do
    @events.each do |event|
      expect(event.venue).not_to be_nil
    end
  end

end

describe Source::Parser::Ical, "when parsing multiple items in an Eventful feed", :type => :model do
  before(:each) do
    url = "http://foo.bar/"
    stub_request(:get, url).to_return(body: read_sample('ical_eventful_many.ics'))
    @events = Source::Parser.to_events(url: url, skip_old: false)
  end

  it "should find multiple events" do
    expect(@events.size).to eq 15
  end

  it "should find venues for events" do
    @events.each do |event|
      expect(event.venue.title).not_to be_nil
    end
  end

  it "should match each event with its venue" do
    event_titles_and_street_addresses = [
      ["iMovie and iDVD Workshop", "7293 SW Bridgeport Road"],
      ["Portland Macintosh Users Group (PMUG)", "Jean Vollum Natural Capital Center"],
      ["Morning Meetings: IT", "622 SE Grand Avenue"]
    ]

    # Make sure each of the above events has the expected street address
    event_titles_and_street_addresses.each do |event_title, street_address|
      expect(@events.find { |event|
        event.title == event_title && event.venue.street_address == street_address
        }).not_to be_nil
      end
  end
end

describe Source::Parser::Ical, "with iCalendar events", :type => :model do

  it "should parse Apple iCalendar v3 format" do
    events = events_from_ical_at('ical_apple_v3.ics')

    expect(events.size).to eq 1
    event = events.first
    expect(event.title).to eq "Coffee with Jason"
    # NOTE Source data does not contain a timezone!?
    expect(event.start_time).to eq Time.zone.parse('2010-04-08 00:00:00')
    expect(event.end_time).to eq Time.zone.parse('2010-04-08 01:00:00')
    expect(event.venue).to be_nil
  end

  it "should parse basic iCalendar format" do
    events = events_from_ical_at('ical_basic.ics')

    expect(events.size).to eq 1
    event = events.first
    expect(event.title).to be_blank
    expect(event.start_time).to eq Time.parse('Wed Jan 17 00:00:00 2007')
    expect(event.venue).to be_nil
  end

  it "should parse basic iCalendar format with a duration and set the correct end time" do
    events = events_from_ical_at('ical_basic_with_duration.ics')

    expect(events.size).to eq 1
    event = events.first
    expect(event.title).to be_blank
    expect(event.start_time).to eq Time.zone.parse('2010-04-08 00:00:00')
    expect(event.end_time).to eq Time.zone.parse('2010-04-08 01:00:00')
    expect(event.venue).to be_nil
  end

  it "should parse Google iCalendar feed with multiple events" do
    events = events_from_ical_at('ical_google.ics')
    # TODO add specs for venues/locations

    expect(events.size).to eq 47

    event = events.first
    expect(event.title).to eq "XPDX (eXtreme Programming) at CubeSpace"
    expect(event.description).to be_blank
    expect(event.start_time).to eq Time.parse("2007-10-24 18:30:00")
    expect(event.end_time).to eq Time.parse("2007-10-24 19:30:00")

    event = events[17]
    expect(event.title).to eq "Code Sprint/Coding Dojo at CubeSpace"
    expect(event.description).to be_blank
    expect(event.start_time).to eq Time.parse("2007-10-17 19:00:00")
    expect(event.end_time).to eq Time.parse("2007-10-17 21:00:00")

    event = events.last
    expect(event.title).to eq "Adobe Developer User Group"
    expect(event.description).to eq "http://pdxria.com/"
    expect(event.start_time).to eq Time.parse("2007-01-16 17:30:00")
    expect(event.end_time).to eq Time.parse("2007-01-16 18:30:00")
  end

  it "should parse non-Vcard locations" do
    events = events_from_ical_at('ical_google.ics')
    expect(events.first.venue.title).to eq 'CubeSpace'
  end

  it "should parse a calendar file with multiple calendars" do
    events = events_from_ical_at('ical_multiple_calendars.ics')
    expect(events.size).to eq 3
    expect(events.map(&:title)).to eq ["Coffee with Jason", "Coffee with Mike", "Coffee with Kim"]
  end

end

describe Source::Parser::Ical, "when importing events with non-local times", :type => :model do

  it "should store time ending in Z as UTC" do
    url = "http://foo.bar/"
    stub_request(:get, url).to_return(body: read_sample('ical_z.ics'))
    @source = Source.new(:title => "Non-local time", :url => url)
    events = @source.create_events!(:skip_old => false)
    event = events.first

    expect(event.start_time).to eq Time.parse('Thu Jul 01 08:00:00 +0000 2010')
    expect(event.end_time).to eq Time.parse('Thu Jul 01 09:00:00 +0000 2010')

    # time should be the same after saving event to, and getting it from, database
    event.save
    e = Event.find(event)
    expect(e.start_time).to eq Time.parse('Thu Jul 01 08:00:00 +0000 2010')
    expect(e.end_time).to eq Time.parse('Thu Jul 01 09:00:00 +0000 2010')
  end

  it "should store time with TZID=GMT in UTC" do
    events = events_from_ical_at('ical_gmt.ics')
    expect(events.size).to eq 1
    event = events.first
    expect(event.start_time).to eq Time.parse('Fri May 07 08:00:00 +0000 2020')
    expect(event.end_time).to eq Time.parse('Fri May 07 09:00:00 +0000 2020')
  end
end

describe Source::Parser::Ical, "munge_gmt_dates", :type => :model do
  it "should return unexpected-format strings unmodified" do
    munged = Source::Parser::Ical.new.send(:munge_gmt_dates, 'justin bieber on a train')
    expect(munged).to eq 'justin bieber on a train'
  end

  it "should return GMT-less ical strings unmodified" do
    icard = %{
BEGIN:VCALENDAR
BEGIN:VEVENT
DTSTART:20200507T080000
DTEND:20200507T090000
END:VEVENT
END:VCALENDAR
    }

    expect(Source::Parser::Ical.new.send(:munge_gmt_dates, icard)).to eq icard
  end

  it "should replace TZID=GMT with a TZID-less UTC time" do
    icard = %{
BEGIN:VCALENDAR
BEGIN:VEVENT
DTSTART;TZID=GMT:20200507T080000
DTEND;TZID=GMT:20200507T090000
END:VEVENT
END:VCALENDAR
    }

    munged = %{
BEGIN:VCALENDAR
BEGIN:VEVENT
DTSTART:20200507T080000Z
DTEND:20200507T090000Z
END:VEVENT
END:VCALENDAR
    }

    expect(Source::Parser::Ical.new.send(:munge_gmt_dates, icard)).to eq munged
  end
end

describe Source::Parser::Ical, "when skipping old events", :type => :model do
  before(:each) do
    url = "http://foo.bar/"
    stub_request(:get, url).to_return(body:
%(BEGIN:VCALENDAR
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
END:VCALENDAR))
    @source = Source.new(title: "Title", url: url)
  end

  # for following specs a 'valid' event does not start after it ends"
  it "should be able to import all valid events" do
    events = @source.create_events!(:skip_old => false)
    expect(events.map(&:title)).to eq [
      "Past start and no end",
      "Current start and no end",
      "Past start and current end",
      "Current start and current end",
      "Past start and past end"
    ]
  end

  it "should be able to skip invalid and old events" do
    events = @source.create_events!(:skip_old => true)
    expect(events.map(&:title)).to eq [
      "Current start and no end",
      "Past start and current end",
      "Current start and current end"
    ]
  end
end
