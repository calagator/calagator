require File.dirname(__FILE__) + '/../../spec_helper'

describe "/events/show" do
  fixtures :events
  
  before(:each) do
    @event = events(:calagator_codesprint)
    assigns[:event] = @event
  end
  
  it "should display a single event" do
    @event.should_receive(:title).exactly(1).times.and_return("Calagator CodeSprint")
    render "/events/show"
  end
  
  it "should render valid XHTML" do
    render "/events/show"
    response.should be_valid_xhtml_fragment
  end
end