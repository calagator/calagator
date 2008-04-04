require File.dirname(__FILE__) + '/../../spec_helper'

describe "/layouts/application" do
  
  it "should render valid XHTML" do
    render "/layouts/application"
    response.should be_valid_xhtml
  end
  
end