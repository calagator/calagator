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
end
