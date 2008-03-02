require File.dirname(__FILE__) + '/../spec_helper'

describe SourcesController do
  
  before(:each) do
    Source.stub!(:new).and_return(@source = mock_model(Source))
    @source.stub!(:to_events).and_return([mock_model(@event = Event, :title => 'Super Event', :source= => true, :save! => true)])
    @source.stub!(:save!)
  end

  it "should create events from a source" do
    @source.should_receive(:to_events).and_return([mock_model(event = Event, :title => 'Super Event', :source= => true, 
        :save! => true )])
    post :create, :source => { :url => 'http://upcoming.yahoo.com/event/390164/' }
  end
  
  it "should save the source object after creating events" do
    @source.should_receive(:save!).and_return(true)
    post :create, :source => { :url => 'http://upcoming.yahoo.com/event/390164/' }
  end
  
  it "should add the http prefix to urls without one"
  
end
