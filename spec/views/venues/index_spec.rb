require 'spec_helper'

describe "/venues" do
  fixtures :all
  
  before(:each) do
    @cubespace = venues(:cubespace)
    assigns[:venues] = [@cubespace]
  end
  
  it "should render valid XHTML" do
    render "/venues/index"
    response.should be_valid_xhtml_fragment
  end
end
