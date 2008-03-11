require File.dirname(__FILE__) + '/../../spec_helper'

describe "/sources/new" do
  
  it "should render valid XHTML" do
    render "/sources/new"
    response.should be_valid_xhtml_fragment
  end
  
end