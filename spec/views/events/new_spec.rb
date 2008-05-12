require File.dirname(__FILE__) + '/../../spec_helper'

describe "/events/new" do
  fixtures :events
  
  before(:each) do
    assigns[:event] = Event.new
  end
  
  it "should render valid XHTML" do
    render "/events/new"
    response.should be_valid_xhtml_fragment
  end
end
