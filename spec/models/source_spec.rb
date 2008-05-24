require File.dirname(__FILE__) + '/../spec_helper'

describe Source, "in general" do
  before(:each) do
    @event = mock_model(Event,
      :title => "Title",
      :description => "Description",
      :url => "http://my.url/",
      :start_time => Time.now + 1.day,
      :venue => nil)
  end

  it "should create events for source from URL" do
    @event.should_receive(:save!)

    source = Source.new(:url => "http://my.url/")
    source.should_receive(:to_events).and_return([@event])

    source.create_events!.should == [@event]
  end

  it "should create source and events from URL" do
    url = "http://my.url/"
    source = mock_model(Source, :url => url)
    source.should_receive(:create_events!).and_return([@event])
    source.should_receive(:save!).and_return(true)

    Source.should_receive(:find_or_create_by_url).and_return(source)
    result = Source.create_sources_and_events_for!(url)

    result.keys.should == [source]
    result.values.first.should == [@event]
  end

  it "should fail to create events for invalid sources" do
    source = Source.new(:url => '\not valid/')
    lambda{ source.to_events }.should raise_error(ActiveRecord::RecordInvalid, /Url has invalid format/i)
  end
end

describe Source, "when reading name" do
  before(:all) do
    @title = "title"
    @url = "http://my.url/"
  end

  before(:each) do
    @source = Source.new
  end

  it "should return nil if no title is available" do
    @source.name.should be_nil
  end

  it "should use title if available" do
    @source.title = @title
    @source.name.should == @title
  end

  it "should use URL if available" do
    @source.url = @url
    @source.name.should == @url
  end

  it "should prefer to use title over URL if both are available" do
    @source.title = @title
    @source.url = @url

    @source.name.should == @title
  end
end

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

  it "should strip leading and trailing whitespace from URL" do
    source = Source.new
    source.url = "     #{@http_url}     "
    source.url.should == @http_url
  end

  it "should be invalid if given invalid URL" do
    source = Source.new
    source.url = '\O.o/'
    source.url.should be_nil
    source.should_not be_valid
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
      :end_time => Time.parse("2008-1-20"),
      :url => "http://www.cubespacepdx.com",
      :venue_id => nil, # TODO what should venue instance be?
    }
      events.first.send(key).should == value
    end
  end

  it "should parse a page with more than one hcal item in it" do
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

  it "should strip html the venue title" do
    hcal_content = read_sample('hcal_upcoming.xml')
    hcal_source = Source.new(:title => "Calendar event feed", :url => "http://mysample.hcal/")
    SourceParser::Base.stub!(:read_url).and_return(hcal_content)
    events = hcal_source.to_events

    events.first.venue.title.should == 'Jive Software Office'
  end

end

describe Source, "with iCalendar events" do
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
    event.start_time.should == Time.parse('Mon Oct 28 14:00:00 -0800 2002')
    event.end_time.should == Time.parse('Mon Oct 28 15:00:00 -0800 2002')
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

  describe Source, "when skipping old events" do
    before(:each) do
      SourceParser::Base.stub!(:read_url).and_return(<<-HERE)
BEGIN:VCALENDAR
X-WR-CALNAME;VALUE=TEXT:NERV
VERSION:2.0
CALSCALE:GREGORIAN
PRODID:-//nerv.go.jp//iCal 1.0//EN
X-WR-TIMEZONE;VALUE=TEXT:US/Eastern
BEGIN:VEVENT
UID:Unit-00
SUMMARY:Rei
DESCRIPTION:Ayanami
DTSTART:#{(Time.now-1.year).strftime("%Y%m%d")}
DTSTAMP:040425
SEQ:0
END:VEVENT
BEGIN:VEVENT
UID:Unit-02
SUMMARY:Asuka
DESCRIPTION:Soryu
DTSTART:#{Time.now.strftime("%Y%m%d")}
DTSTAMP:040425
SEQ:1
END:VEVENT
END:VCALENDAR
      HERE
      @source = Source.new(:title => "Title", :url => "http://my.url/")
    end

    it "should be able to import all events" do
      events = @source.to_events(:skip_old => false)
      events.size.should == 2
      events.first.title == "Rei"
      events.last.title == "Asuka"
    end

    it "should be able to skip old events" do
      events = @source.to_events(:skip_old => true)
      events.size.should == 1
      events.first.title == "Asuka"
    end
  end
end

describe Source, "when importing events" do
  fixtures :events, :venues

  it "should not create a new event when importing an identical event" do
    hcal_content = read_sample('hcal_dup_event_dup_venue.xml')
    hcal_source = Source.new(:title => "Calendar event feed", :url => "http://mysample.hcal/")
    SourceParser::Base.stub!(:read_url).and_return(hcal_content)

    events = hcal_source.to_events

    events.first.should_not be_a_new_record # it should return an existing event record and not create a new one
  end

  it "should create two events when importing two non-identical events"

  it "two events and two venues should be created when importing two identical events with two non-identical venues"

end
