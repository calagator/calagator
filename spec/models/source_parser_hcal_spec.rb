require File.dirname(__FILE__) + '/../spec_helper'

describe SourceParser::Hcal, "with hCalendar events" do
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

  it "should strip html from the venue title" do
    hcal_content = read_sample('hcal_upcoming.xml')
    hcal_source = Source.new(:title => "Calendar event feed", :url => "http://mysample.hcal/")
    SourceParser::Base.stub!(:read_url).and_return(hcal_content)
    events = hcal_source.to_events

    events.first.venue.title.should == 'Jive Software Office'
  end

end

describe SourceParser::Hcal, "when importing events" do
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

  it "should replace a venue identical to a squashed duplicate with the master venue"  do
    Event.destroy_all
    Source.destroy_all
    Venue.destroy_all

    dummy_source = Source.new(:title => "Dummy", :url => "http://IcalEventWithSquashedVenue.com/")
    dummy_source.save
    master_venue = Venue.new(:title => "Master")
    master_venue.save
    squashed_venue = Venue.new(
      :title => "Squashed Duplicate Venue",
      :duplicate_of_id => master_venue.id)
    squashed_venue.save

    ical_content = read_sample('ical_event_with_squashed_venue.ics')
    SourceParser::Base.stub!(:read_url).and_return(ical_content)
    source = Source.new(:title => "Event with squashed venue", :url => "http://IcalEventWithSquashedVenue.com/")

    events = source.to_events(:skip_old => false)

    event = events.first
    event.venue.title.should == "Master"
  end

end
