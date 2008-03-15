require File.dirname(__FILE__) + '/../spec_helper'

describe SourcesController do
  before(:each) do
    @venue = mock_model(Venue, :source => nil, :source= => true, :save! =>true)
    @event = mock_model(Event, :title => 'Super Event', :source= => true, :save! => true, :venue => @venue)
    @source = mock_model(Source, :to_events => [@event], :save! => true, :valid? => true,
                                 :url => 'http://upcoming.yahoo.com/event/390164/')
    Source.stub!(:new).and_return(@source)
  end

  it "should create events from a source" do
    post :create
  end

  it "should save the source object after creating events" do
    @source.should_receive(:save!).and_return(true)
    post :create
  end

  it "should assign newly created events to the source" do
    @event.should_receive(:source=).and_return(true)
    @event.should_receive(:save!).and_return(true)
    post :create
  end

  it "should assign newly created venues to the source" do
    @venue.should_receive(:source=).and_return(true)
    @venue.should_receive(:save!).and_return(true)
    post :create
  end
  
  it "should give a nice error message when given a bad URL" do
    @source.should_receive(:to_events).and_raise(OpenURI::HTTPError.new("bad_url", nil))
    errors = mock_model(ActiveRecord::Errors, :full_messages => %w{bad})
    errors.stub!(:add_to_base)
    @source.should_receive(:errors).at_least(1).times.and_return(errors)
    post :create
    flash[:failure].should match(/Unable to import: bad/)
  end
end
