require File.dirname(__FILE__) + '/../../spec_helper'

describe "/events/duplicates" do
  fixtures :events
  
  before(:each) do
    @codesprint = events(:calagator_codesprint)
    @tomorrow = events(:tomorrow)
    @day_after_tomorrow = events(:day_after_tomorrow)
    assigns[:grouped_events] = [[nil, [@codesprint, @tomorrow, @day_after_tomorrow]]]
  end
  
  it "should render valid XHTML" do
    render "/events/duplicates"
    response.should be_valid_xhtml_fragment
  end
end