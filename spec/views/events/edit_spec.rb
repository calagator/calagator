require File.dirname(__FILE__) + '/../../spec_helper'

describe "/events/edit" do
  fixtures :events
  
  before(:each) do
    @codesprint = events(:calagator_codesprint)
    assigns[:event] = @codesprint
  end
  
  it "should render valid XHTML" do
    render "/events/edit"
    response.should be_valid_xhtml_fragment
  end
end