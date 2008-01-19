require File.dirname(__FILE__) + '/../spec_helper'

describe Source do
  before(:each) do
    @source = Source.new
  end

  it "should be valid" do
    @source.should be_valid
  end
end
