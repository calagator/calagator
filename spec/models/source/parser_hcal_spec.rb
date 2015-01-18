require 'spec_helper'

describe Source::Parser::Hcal, "with hCalendar events", :type => :model do
  it "should parse hcal" do
    url = "http://mysample.hcal/"
    stub_request(:get, url).to_return(body: read_sample('hcal_single.xml'))
    hcal_source = Source.new(title: "Calendar event feed", url: url)

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
    url = "http://mysample.hcal/"
    stub_request(:get, url).to_return(body: read_sample('hcal_upcoming_v1.html'))
    hcal_source = Source.new(title: "Calendar event feed", url: url)

    events = hcal_source.to_events

    expect(events.first.venue.title).to eq 'Jive Software Office'
  end

  it "should parse a page with multiple events" do
    url = "http://mysample.hcal/"
    stub_request(:get, url).to_return(body: read_sample('hcal_multiple.xml'))
    hcal_source = Source.new(title: "Calendar event feed", url: url)

    events = hcal_source.to_events
    expect(events.size).to eq 2
    first, second = *events
    expect(first.start_time).to eq Time.parse('2008-1-19')
    expect(first.end_time).to eq Time.parse('2008-01-20')
    expect(second.start_time).to eq Time.parse('2008-2-2')
    expect(second.end_time).to eq Time.parse('2008-02-03')
  end
end

describe Source::Parser::Hcal, "with hCalendar to Venue parsing", :type => :model do
  it "should extract an Venue from an hCalendar text" do
    url = "http://mysample.hcal/"
    stub_request(:get, url).to_return(body: read_sample('hcal_upcoming_v1.html'))

    events = Source::Parser::Hcal.to_events(url: url)
    event = events.first
    venue = event.venue

    expect(venue).to be_a_kind_of(Venue)
    expect(venue.locality).to eq "portland"
    expect(venue.street_address).to eq "317 SW Alder St Ste 500"
    expect(venue.latitude).to be_within(0.1).of(45.5191)
    expect(venue.longitude).to be_within(0.1).of(-122.675)
    expect(venue.postal_code).to eq "97204"
  end
end
