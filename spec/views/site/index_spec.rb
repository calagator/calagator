require File.dirname(__FILE__) + '/../../spec_helper'

describe "/site/index" do
  fixtures :events
  
  before(:each) do
    @codesprint = events(:calagator_codesprint)
    @tomorrow = events(:tomorrow)
    @day_after_tomorrow = events(:day_after_tomorrow)
    
    @events = {:today => {:count => 1, :results => [@codesprint], :skipped => 0}, :tomorrow => {:count => 1, :results => [@tomorrow], :skipped => 0}, :later => {:count=> 1, :results => [@day_after_tomorrow], :skipped => 0}}
    
    assigns[:events] = @events
  end
  
  it "should render valid XHTML" do
    render "/site/index"
    response.should be_valid_xhtml_fragment
  end

end

