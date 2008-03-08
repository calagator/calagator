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
end