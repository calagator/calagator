require File.dirname(__FILE__) + '/../../spec_helper'

describe "/venues/new" do
  before(:each) do
    assigns[:venue] = Venue.new
  end
  
  it "should render valid XHTML" do
    render "/venues/new"
    response.should be_valid_xhtml_fragment
  end
end