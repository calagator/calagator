require File.dirname(__FILE__) + '/../spec_helper'

describe SourcesController do
  before(:each) do
    @venue = mock_model(Venue,
      :source => nil,
      :source= => true,
      :save! => true)

    @event = mock_model(Event,
      :title => "Super Event",
      :source= => true,
      :save! => true,
      :venue => @venue,
      :start_time => Time.now+1.week,
      :end_time => nil)

    @source = Source.new(:url => "http://my.url/")
    @source.stub!(:save!).and_return(true)
    @source.stub!(:to_events).and_return([@event])

    Source.stub!(:new).and_return(@source)
    Source.stub!(:find_or_create_by_url).and_return(@source)
  end

  it "should redirect the index to the new source form" do
    get :index
    response.should redirect_to(new_source_path)
  end

  it "should provide a way to create new sources" do
    get :new
    assigns(:source).should be_a_kind_of(Source)
    assigns(:source).should be_a_new_record
  end

  it "should treat update as a create" do
    @source.should_receive(:save!).twice
    put :update
    flash[:success].should =~ /Imported/i
  end

  it "should save the source object after creating events" do
    # twice: create and save
    @source.should_receive(:save!).twice
    post :create
    flash[:success].should =~ /Imported/i
  end

  it "should assign newly created events to the source" do
    @event.should_receive(:save!)
    post :create
  end

  it "should assign newly created venues to the source" do
    @venue.should_receive(:save!)
    post :create
  end

  it "should limit the number of created events to list in the flash" do
    excess = 5
    events = (1..(SourcesController::MAXIMUM_EVENTS_TO_DISPLAY_IN_FLASH+excess))\
      .inject([]){|result,i| result << @event; result}
    @source.should_receive(:to_events).and_return(events)
    post :create
    flash[:success].should =~ /And #{excess} other events/si
  end

  it "should give a nice error message when given a bad URL" do
    @source.should_receive(:to_events).and_raise(OpenURI::HTTPError.new("bad_url", nil))
    errors = ActiveRecord::Errors.new(@source)
    errors.stub!(:full_messages).and_return(%w(bad))
    @source.should_receive(:errors).at_least(1).times.and_return(errors)
    post :create
    flash[:failure].should =~ /Unable to import: bad/
  end
end
