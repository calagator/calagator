require File.dirname(__FILE__) + '/../spec_helper'

describe SourcesController do

  it "should create events from a source" do
    Source.stub!(:new).and_return(source = mock_model(Source))
    source.should_receive(:to_events).and_return([mock_model(Event, :title => 'Super Event', :save! => true)])
    source.stub!(:save!)
    post :create, :source => { :url => 'http://upcoming.yahoo.com/event/390164/' }
  end
  
  it "should save the source object after creating events" do
    Source.stub!(:new).and_return(source = mock_model(Source))
    source.stub!(:to_events).and_return([mock_model(Event, :title => 'Super Event', :save! => true)])
    source.should_receive(:save!).and_return(true)
    post :create, :source => { :url => 'http://upcoming.yahoo.com/event/390164/' }
  end
  
end
