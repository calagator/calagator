require File.dirname(__FILE__) + '/../spec_helper'

describe "Event with default blacklist" do
  before(:each) do
    @event = Event.new(:title => "Title", :start_time => Time.now)
  end

  it "should be valid when clean" do
    @event.should be_valid
  end

  it "should not be valid when it features blacklisted word" do
    @event.title = "Foo bar cialis"
    @event.should_not be_valid
  end
end

describe "Event with custom blacklist" do
  class Event
    validates_blacklist_on :title, :patterns => [/Kltpzyxm/i]
  end

  before(:each) do
    @event = Event.new(:title => "Title", :start_time => Time.now)
  end

  it "should be valid when clean" do
    @event.should be_valid
  end

  it "should not be valid when it features custom blacklisted word" do
    @event.title = "fooKLTPZYXMbar"
    @event.should_not be_valid
  end
end
