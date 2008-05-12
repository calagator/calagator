require File.dirname(__FILE__) + '/../../spec_helper'

describe "/site/index" do
  fixtures :events
  
  before(:each) do
    @codesprint = events(:calagator_codesprint)
    @tomorrow = events(:tomorrow)
    @day_after_tomorrow = events(:day_after_tomorrow)
    
    @events = [@codesprint, @tomorrow, @day_after_tomorrow]
    
    assigns[:events] = @events
    assigns[:events_today] = @events
    assigns[:events_tomorrow] = @events
    assigns[:events_later] = @events
    assigns[:recently_added_events] = @events
  end
  
  it "should render valid XHTML" do
    render "/site/index"
    response.should be_valid_xhtml_fragment
  end

end

