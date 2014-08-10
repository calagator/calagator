require 'spec_helper'

describe SourceParser::Hcal, "with hCalendar events" do
  it "should parse hcal" do
    hcal_content = read_sample('hcal_single.xml')
    hcal_source = Source.new(:title => "Calendar event feed", :url => "http://mysample.hcal/")
    SourceParser::Base.should_receive(:read_url).and_return(hcal_content)

    events = hcal_source.to_events

    events.size.should eq 1
    for key, value in {
      :title => "Calendar event",
      :description => "Check it out!",
      :start_time => Time.parse("2008-1-19"),
      :end_time => Time.parse("2008-1-20"),
      :url => "http://www.cubespacepdx.com",
      :venue_id => nil, # TODO what should venue instance be?
    }
      events.first.send(key).should eq value
    end
  end

  it "should strip html from the venue title" do
    hcal_content = read_sample('hcal_upcoming_v1.html')
    hcal_source = Source.new(:title => "Calendar event feed", :url => "http://mysample.hcal/")
    SourceParser::Base.stub(:read_url).and_return(hcal_content)
    events = hcal_source.to_events

    events.first.venue.title.should eq 'Jive Software Office'
  end

  it "should parse a page with multiple events" do
    hcal_content = read_sample('hcal_multiple.xml')

    hcal_source = Source.new(:title => "Calendar event feed", :url => "http://mysample.hcal/")
    SourceParser::Base.should_receive(:read_url).and_return(hcal_content)

    events = hcal_source.to_events
    events.size.should eq 2
    first, second = *events
    first.start_time.should eq Time.parse('2008-1-19')
    first.end_time.should eq Time.parse('2008-01-20')
    second.start_time.should eq Time.parse('2008-2-2')
    second.end_time.should eq Time.parse('2008-02-03')
  end
end

describe SourceParser::Hcal, "with hCalendar to AbstractLocation parsing" do
  it "should extract an AbstractLocation from an hCalendar text" do
    hcal_upcoming = read_sample('hcal_upcoming_v1.html')

    SourceParser::Hcal.stub(:read_url).and_return(hcal_upcoming)
    abstract_events = SourceParser::Hcal.to_abstract_events(:url => "http://foo.bar/")
    abstract_event = abstract_events.first
    abstract_location = abstract_event.location

    abstract_location.should be_a_kind_of(SourceParser::AbstractLocation)
    abstract_location.locality.should eq "portland"
    abstract_location.street_address.should eq "317 SW Alder St Ste 500"
    abstract_location.latitude.should be_within(0.1).of(45.5191)
    abstract_location.longitude.should be_within(0.1).of(-122.675)
    abstract_location.postal_code.should eq "97204"
  end
end
