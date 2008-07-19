require File.dirname(__FILE__) + '/../../spec_helper'

describe "/venues" do
  fixtures :venues
  
  before(:each) do
    @cubespace = venues(:cubespace)
    assigns[:venues] = [@cubespace]
  end
  
  it "should render valid XHTML" do
    render "/venues/index"
    response.should be_valid_xhtml_fragment
  end

  it "should display a map if any venues have locations" do
    pending "no Geocoder API key found" if defined?(GoogleMap::GOOGLE_APPLICATION_ID).nil?
    render "/venues/index"
    response.should have_tag('div#google_map')
  end
  
  it "should not display a map if no venues have locations" do
    pending "no Geocoder API key found" if defined?(GoogleMap::GOOGLE_APPLICATION_ID).nil?
    @cubespace.latitude = nil
    render "/venues/index"
    response.should_not have_tag('div#google_map')
  end
end