require File.dirname(__FILE__) + '/../spec_helper'

describe SourcesController do

  it "should create events from a source" do
    Source.stub!(:new).and_return(source = mock_model(Source))
    source.should_receive(:to_events).and_return([mock_model(Event, :title => 'Super Event', :save! => true)])
    post :create, :source => { :url => 'http://upcoming.yahoo.com/event/390164/' }
  end
  
end
