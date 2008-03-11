require File.dirname(__FILE__) + '/../spec_helper'

describe SourcesController do
  
  before(:each) do
    Source.stub!(:new).and_return(@source = mock_model(Source))
    @source.stub!(:to_events).and_return([@event = mock_model(Event, :title => 'Super Event', :source= => true, :save! => true, :venue => @venue = mock_model(Venue, :source => nil, :source= => true, :save! =>true))])
    @source.stub!(:save!)
  end

  it "should create events from a source" do
    @source.should_receive(:to_events).and_return(
      [mock_model(event = Event, 
        :title => 'Super Event', 
        :source= => true, 
        :save! => true, 
        :venue => mock_model(Venue, :source => nil, :source= => true, :save! =>true))])
    post :create, :source => { :url => 'http://upcoming.yahoo.com/event/390164/' }
  end
  
  it "should save the source object after creating events" do
    @source.should_receive(:save!).and_return(true)
    post :create, :source => { :url => 'http://upcoming.yahoo.com/event/390164/' }
  end
  
  it "should assign newly created events to the source" do
    # TODO doesn't actually provide example that an object was set
    @event.should_receive(:source=).and_return(true)
    @event.should_receive(:save!).and_return(true)
    post :create, :source => { :url => 'http://upcoming.yahoo.com/event/390164/' }
  end
  
  it "should assign newly created venues to the source" do
    # TODO doesn't actually provide example that an object was set
    @venue.should_receive(:source=).and_return(true)
    @venue.should_receive(:save!).and_return(true)
    post :create, :source => { :url => 'http://upcoming.yahoo.com/event/390164/' }
  end  
  
  it "should substitute http for unsupported url schemes" do
    Source.should_receive(:new).with({ 'url' => 'http://upcoming.yahoo.com/event/390164/' }).and_return(@source)
    post :create, :source => { :url => 'webcal://upcoming.yahoo.com/event/390164/' }
  end
  
  it "should add the http prefix to urls without one" do    
    Source.should_receive(:new).with({ 'url' => 'http://upcoming.yahoo.com/event/390164/' }).and_return(@source)
    post :create, :source => { :url => 'upcoming.yahoo.com/event/390164/' }
  end
end
