require 'spec_helper'

module Calagator
  describe Source::Parser::Ical, type: :model do
    around do |example|
      Timecop.freeze("2000-01-01") do
        example.run
      end
    end

    def events_from_ical_at(filename)
      url = "http://foo.bar/"
      source = Calagator::Source.new(:title => "Calendar event feed", :url => url)
      stub_request(:get, url).to_return(body: read_sample(filename))
      return source.to_events
    end

    describe "in general" do
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

    describe "when parsing events and their venues" do
      before(:each) do
        url = "http://foo.bar/"
        stub_request(:get, url).to_return(body: read_sample('ical_upcoming_many.ics'))
        @events = Source::Parser.to_events(url: url)
      end

      it "venues should be" do
        @events.each do |event|
          expect(event.venue).not_to be_nil
        end
      end

    end

    describe "when parsing multiple items in an Eventful feed" do
      before(:each) do
        url = "http://foo.bar/"
        stub_request(:get, url).to_return(body: read_sample('ical_eventful_many.ics'))
        @events = Source::Parser.to_events(url: url)
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
        expect(@events.map { |event| [event.title, event.venue.street_address] }).to eq [
          ["iMovie and iDVD Workshop", "7293 SW Bridgeport Road"],
          ["iMovie and iDVD Workshop", "700 Southwest Fifth Avenue Suite #1035"],
          ["Portland Macintosh Users Group (PMUG)", "Jean Vollum Natural Capital Center"],
          ["Morning Meetings: IT", "622 SE Grand Avenue"],
          ["Portland Python Users' Group", "622 SE Grand Avenue"],
          ["Computer Basics Class", "12375 SW Fifth Street"],
          ["Code 'n' Splode", "622 SE Grand Avenue"],
          ["Google Analytics Seminars for Success in Portland,OR", "310 SW Lincoln Street"],
          ["PDXPHP Monthly Meeting", "1731 SE Tenth Avenue"],
          ["Portland Ruby Brigade", "622 SE Grand Avenue"],
          ["Portland Cisco Router Training: 2-Day Hands-On Seminar", "15525 NW Gateway Court"],
          ["Post Card & Souvenir Distributors Association Convention & Tra de Show", "1000 NE Multnomah"],
          ["Portland Cisco ASA Training:  2-Day Hands-On Seminar", "15525 NW Gateway Court"],
          ["Mythbusters", "Southwest Broadway at Main Street"],
          ["Wood Technology Clinic & Show", "777 NE Martin Luther King Jr Boulevard"],
        ]
      end
    end

    describe "with iCalendar events" do
      it "should parse Apple iCalendar v3 format" do
        events = events_from_ical_at('ical_apple_v3.ics')

        expect(events.size).to eq 1
        event = events.first
        expect(event.title).to eq "Coffee with Jason"
        expect(event.start_time).to eq Time.zone.parse('2010-04-08 00:00:00 PDT -07:00')
        expect(event.end_time).to eq Time.zone.parse('2010-04-08 01:00:00 PDT -07:00')
        expect(event.venue).to be_nil
      end

      it "should parse basic iCalendar format" do
        events = events_from_ical_at('ical_basic.ics')

        expect(events.size).to eq 1
        event = events.first
        expect(event.title).to be_blank
        expect(event.start_time).to eq Time.zone.parse('Wed Jan 17 00:00:00 2007')
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
        expect(event.start_time).to eq Time.parse("2007-10-24 18:30:00 PDT")
        expect(event.end_time).to eq Time.parse("2007-10-24 19:30:00 PDT")

        event = events[17]
        expect(event.title).to eq "Code Sprint/Coding Dojo at CubeSpace"
        expect(event.description).to be_blank
        expect(event.start_time).to eq Time.parse("2007-10-17 19:00:00 PDT")
        expect(event.end_time).to eq Time.parse("2007-10-17 21:00:00 PDT")

        event = events.last
        expect(event.title).to eq "Adobe Developer User Group"
        expect(event.description).to eq "http://pdxria.com/"
        expect(event.start_time).to eq Time.parse("2007-01-16 17:30:00 PST")
        expect(event.end_time).to eq Time.parse("2007-01-16 18:30:00 PST")
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

      it "should not swallow errors" do
        expect(RiCal).to receive(:parse_string).and_raise(TypeError)
        expect { events_from_ical_at('ical_multiple_calendars.ics') }.to raise_error(TypeError)
      end
    end

    describe "when importing events with non-local times" do
      it "should store time ending in Z as UTC" do
        url = "http://foo.bar/"
        stub_request(:get, url).to_return(body: read_sample('ical_z.ics'))
        @source = Source.new(:title => "Non-local time", :url => url)
        events = @source.create_events!
        event = events.first

        expect(event.start_time).to eq Time.parse('Thu Jul 01 08:00:00 +0000 2010')
        expect(event.end_time).to eq Time.parse('Thu Jul 01 09:00:00 +0000 2010')

        # time should be the same after saving event to, and getting it from, database
        event.save
        event.reload
        expect(event.start_time).to eq Time.parse('Thu Jul 01 08:00:00 +0000 2010')
        expect(event.end_time).to eq Time.parse('Thu Jul 01 09:00:00 +0000 2010')
      end

      it "should store time with TZID=GMT in UTC" do
        events = events_from_ical_at('ical_gmt.ics')
        expect(events.size).to eq 1
        event = events.first
        expect(event.start_time).to eq Time.parse('Fri May 07 08:00:00 +0000 2020')
        expect(event.end_time).to eq Time.parse('Fri May 07 09:00:00 +0000 2020')
      end
    end

    describe "when skipping old events" do
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

      it "should be able to skip invalid and old events" do
        events = @source.create_events!
        expect(events.map(&:title)).to eq [
          "Current start and no end",
          "Past start and current end",
          "Current start and current end"
        ]
      end
    end

    describe "when parsing an invalid ical" do
      before(:each) do
        url = "http://foo.bar/"
        stub_request(:get, url).to_return(body:
                                          %(BEGIN:VCALENDAR
BEGIN:VEVENT
OMGWTFBBQ
END:VCALENDAR))
        @source = Source.new(title: "Title", url: url)
      end

      it "should return no events" do
        @source.create_events!.should == []
      end
    end
  end
end
