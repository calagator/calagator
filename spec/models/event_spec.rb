require File.dirname(__FILE__) + '/../spec_helper'

describe Event do
  before(:all) do
    @hcal_basic = read_sample('hcal_basic.xml')
    @hcal_upcoming = read_sample('hcal_upcoming.xml')
  end

  before(:each) do
    @event = Event.new
  end

  it "should have a source" do
    @event.source.should be_nil
  end

  it "should parse an AbstractEvent into an Event" do
    event = Event.new(:title => true, :description => true, :start_time => true, :url => true)
    Event.should_receive(:new).and_return(event)
    abstract_event = SourceParser::AbstractEvent.new('title', 'description', 'start_time', 'url')

    Event.from_abstract_event(abstract_event).should == event
  end

  it "should parse an Event into an hCalendar" do
    @event.url = 'http://www.web2con.com/'
    @event.title = 'Web 2.0 Conference'
    @event.start_time = Time.parse('2007-10-05')
    @event.venue = mock_model(Venue, :title => 'Argent Hotel, San Francisco, CA')

    actual_hcal = @event.to_hcal
    actual_hcal.should =~ Regexp.new(@hcal_basic.gsub(/\s+/, '\s+')) # Ignore spacing changes
  end

end
