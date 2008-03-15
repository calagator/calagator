require File.dirname(__FILE__) + '/../../spec_helper'

describe "/sources/new" do

  before(:each) do
    assigns[:source] = Source.new
  end
  
  it "should render valid XHTML" do
    render "/sources/new"
    response.should be_valid_xhtml_fragment
  end
  
end