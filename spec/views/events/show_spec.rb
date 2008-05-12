require File.dirname(__FILE__) + '/../../spec_helper'

describe "/events/show" do
  fixtures :events, :venues
  
  before(:each) do
    @event = events(:calagator_codesprint)
    assigns[:event] = @event
  end
  
  it "should display a single event" do
    @event.should_receive(:title).at_least(1).times.and_return("Calagator CodeSprint")
    render "/events/show"
  end
  
  it "should render valid XHTML" do
    render "/events/show"
    response.should be_valid_xhtml_fragment
  end

  it "should display a map if the event's venue has a location" do
    pending "no Geocoder API key found" if defined?(GoogleMap::GOOGLE_APPLICATION_ID).nil?
    render "/events/show"
    response.should have_tag('div#google_map')
  end
  
  it "should not display a map if the event's venue has no location" do
    pending "no Geocoder API key found" if defined?(GoogleMap::GOOGLE_APPLICATION_ID).nil?
    @event.venue.latitude = nil
    render "/events/show"
    response.should_not have_tag('div#google_map')
  end

  it "should should render Google Calendar reminder link" do
    render "/events/show"
    response.should have_tag('a[href*=http://www.google.com/calendar/event?action=TEMPLATE]')
  end
  
  it "should export address to Google Calendar" do
    render "/events/show"
    # location=CubeSpace loc:622 SE Grand Ave., in Portland, Oregon.
    response.should have_tag('a[href*=location=CubeSpace%20loc%3A622%20SE%20Grand%20Ave.%2C%20in%20Portland%2C%20Oregon.]')
  end
end

describe 'Google Calendar Integration for Venue with Multi-Line Address' do
  fixtures :events, :venues

  before(:each) do
    @event = events(:duplicate_event)
    assigns[:event] = @event
  end

  it "should should render Google Calendar reminder link" do
    render "/events/show"
    response.should have_tag('a[href*=http://www.google.com/calendar/event?action=TEMPLATE]')
  end
  
  it "should export address to Google Calendar" do
    render "/events/show"
    # location=CubeSpace2 loc:622 SE Grand Ave., Portland OR 97204
    response.should have_tag('a[href*=location=CubeSpace2%20loc%3A622%20SE%20Grand%20Ave.%2C%20Portland%20OR%2097204]')
  end
end