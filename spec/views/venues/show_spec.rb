require File.dirname(__FILE__) + '/../../spec_helper'

describe "/venues/show" do
  fixtures :venues
  
  before(:each) do
    @cubespace = venues(:cubespace)
    assigns[:venue] = @cubespace
  end
  
  it "should render valid XHTML" do
    render "/venues/show"
    response.should be_valid_xhtml_fragment
  end
  
  it "should display a map for a venue with a location" do
    pending "no Geocoder API key found" if defined?(GoogleMap::GOOGLE_APPLICATION_ID).nil?
    render "/venues/show"
    response.should have_tag('div#google_map')
  end
  
  it "should not display a map if the venue has no location" do
    pending "no Geocoder API key found" if defined?(GoogleMap::GOOGLE_APPLICATION_ID).nil?
    @cubespace.latitude = nil
    render "/venues/show"
    response.should_not have_tag('div#google_map')
  end
end