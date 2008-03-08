require File.dirname(__FILE__) + '/../../spec_helper'

describe "/sources/index" do
  
  it "should render valid XHTML" do
    render "/sources/index"
    response.should be_valid_xhtml_fragment
  end
  
end