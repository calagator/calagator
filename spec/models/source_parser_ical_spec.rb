require File.dirname(__FILE__) + '/../spec_helper'

describe SourceParser::Ical, "in general" do
  it "should read http URLs as-is" do
    http_url = "http://foo.bar/"
    uri = mock_model(URI, :read => 42)
    URI.should_receive(:parse).with(http_url).and_return(uri)

    SourceParser::Ical.read_url(http_url).should == 42
  end

  it "should read webcal URLs as http" do
    webcal_url = "webcal://foo.bar/"
    http_url   = "http://foo.bar/"
    uri = mock_model(URI, :read => 42)
    URI.should_receive(:parse).with(http_url).and_return(uri)

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
    @events = SourceParser.to_abstract_events(:url => "intercepted")
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
    @events = SourceParser.to_abstract_events(:url => "intercepted")
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
