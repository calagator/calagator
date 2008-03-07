require File.dirname(__FILE__) + '/../../spec_helper'

describe "/events" do
  fixtures :events
  
  before(:each) do
    @codesprint = events(:calagator_codesprint)
    @tomorrow = events(:tomorrow)
    @day_after_tomorrow = events(:day_after_tomorrow)
    assigns[:events] = [@codesprint, @tomorrow, @day_after_tomorrow]
    assigns[:start_date] = Time.now
    assigns[:end_date] = Time.now
  end
  
  it "should display a list of events" do
    @codesprint.should_receive(:title).exactly(1).times.and_return("Calagator CodeSprint")
    render "/events/index"
  end
  
  it "should render valid XHTML" do
    render "/events/index"
    response.should be_valid_xhtml_fragment
  end
end