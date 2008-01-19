require File.dirname(__FILE__) + '/../spec_helper'

describe Venue do
  before(:each) do
    @venue = Venue.new
  end

  it "should be valid" do
    @venue.should be_valid
  end
end
