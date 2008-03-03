require File.dirname(__FILE__) + '/../spec_helper'

describe Event do
  before(:each) do
    @event = Event.new

    @basic_hcal = read_sample('hcal_basic.xml')
    @basic_venue = mock_model(Venue, :title => 'Argent Hotel, San Francisco, CA')
    @basic_event = Event.new(
      :title => 'Web 2.0 Conference',
      :url => 'http://www.web2con.com/',
      :start_time => Time.parse('2007-10-05'),
      :venue => @basic_venue)
  end

  it "should parse an AbstractEvent into an Event" do
    event = Event.new(:title => true, :description => true, :start_time => true, :url => true)
    Event.should_receive(:new).and_return(event)
    abstract_event = SourceParser::AbstractEvent.new('title', 'description', 'start_time', 'url')

    Event.from_abstract_event(abstract_event).should == event
  end

  it "should parse an Event into an hCalendar" do
    actual_hcal = @basic_event.to_hcal
    actual_hcal.should =~ Regexp.new(@basic_hcal.gsub(/\s+/, '\s+')) # Ignore spacing changes
  end

  it "should parse an Event into an iCalendar" do
    actual_ical = @basic_event.to_ical

    abstract_events = SourceParser.to_abstract_events("Ical", :content => actual_ical)

    abstract_events.size.should == 1
    abstract_event = abstract_events.first
    abstract_event.title.should == @basic_event.title
    abstract_event.url.should == @basic_event.url

    # TODO implement venue generation
    #abstract_event.location.title.should == @basic_event.venue.title
    abstract_event.location.should be_nil
  end
end
