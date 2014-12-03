require 'spec_helper'

describe SourceParser::Hcal, "with hCalendar events", :type => :model do
  it "should parse hcal" do
    hcal_content = read_sample('hcal_single.xml')
    hcal_source = Source.new(:title => "Calendar event feed", :url => "http://mysample.hcal/")
    expect(SourceParser::Base).to receive(:read_url).and_return(hcal_content)

    events = hcal_source.to_events

    expect(events.size).to eq 1
    for key, value in {
      :title => "Calendar event",
      :description => "Check it out!",
      :start_time => Time.parse("2008-1-19"),
      :end_time => Time.parse("2008-1-20"),
      :url => "http://www.cubespacepdx.com",
      :venue_id => nil, # TODO what should venue instance be?
    }
      expect(events.first.send(key)).to eq value
    end
  end

  it "should strip html from the venue title" do
    hcal_content = read_sample('hcal_upcoming_v1.html')
    hcal_source = Source.new(:title => "Calendar event feed", :url => "http://mysample.hcal/")
    allow(SourceParser::Base).to receive(:read_url).and_return(hcal_content)
    events = hcal_source.to_events

    expect(events.first.venue.title).to eq 'Jive Software Office'
  end

  it "should parse a page with multiple events" do
    hcal_content = read_sample('hcal_multiple.xml')

    hcal_source = Source.new(:title => "Calendar event feed", :url => "http://mysample.hcal/")
    expect(SourceParser::Base).to receive(:read_url).and_return(hcal_content)

    events = hcal_source.to_events
    expect(events.size).to eq 2
    first, second = *events
    expect(first.start_time).to eq Time.parse('2008-1-19')
    expect(first.end_time).to eq Time.parse('2008-01-20')
    expect(second.start_time).to eq Time.parse('2008-2-2')
    expect(second.end_time).to eq Time.parse('2008-02-03')
  end
end

describe SourceParser::Hcal, "with hCalendar to AbstractLocation parsing", :type => :model do
  it "should extract an AbstractLocation from an hCalendar text" do
    hcal_upcoming = read_sample('hcal_upcoming_v1.html')

    allow(SourceParser::Hcal).to receive(:read_url).and_return(hcal_upcoming)
    abstract_events = SourceParser::Hcal.to_abstract_events(:url => "http://foo.bar/")
    abstract_event = abstract_events.first
    abstract_location = abstract_event.location

    expect(abstract_location).to be_a_kind_of(SourceParser::AbstractLocation)
    expect(abstract_location.locality).to eq "portland"
    expect(abstract_location.street_address).to eq "317 SW Alder St Ste 500"
    expect(abstract_location.latitude).to be_within(0.1).of(45.5191)
    expect(abstract_location.longitude).to be_within(0.1).of(-122.675)
    expect(abstract_location.postal_code).to eq "97204"
  end
end
