require File.dirname(__FILE__) + '/../../spec_helper'

describe "/venues/duplicates" do
  fixtures :venues
  
  before(:each) do
    @cubespace = venues(:cubespace)
    assigns[:grouped_venues] = [[nil, [@cubespace]]]
  end
  
  it "should render valid XHTML" do
    render "/venues/duplicates"
    response.should be_valid_xhtml_fragment
  end
end