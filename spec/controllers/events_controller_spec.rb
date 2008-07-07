require File.dirname(__FILE__) + '/../spec_helper'

describe EventsController, "when displaying events" do
  it "should show an event" do
    event = Event.new(:start_time => Time.now)
    Event.should_receive(:find).and_return(event)

    get "show", :id => 1234
    response.should be_success
  end

  it "should redirect from a duplicate event to its master" do
    master = mock_model(Event, :id => 4321)
    event = Event.new(:start_time => Time.now, :duplicate_of => master)
    Event.should_receive(:find).and_return(event)

    get "show", :id => 1234
    response.should redirect_to(event_path(master))
  end

  it "should show an error when asked to display a non-existent event" do
    Event.should_receive(:find).and_raise(ActiveRecord::RecordNotFound)

    get "show", :id => 1234
    response.should redirect_to(events_path)
    flash[:failure].should_not be_blank
  end
end

describe EventsController, "when creating or updating events" do
  before(:each) do
    # Fields marked with "###" may be filled in by examples to alter behavior
    @params = {
      :end_date       => "2008-06-04",
      :start_date     => "2008-06-03",
      :event => {
        "title"       => "MyVenue",
        "url"         => "http://my.venue",
        "description" => "Wheeeee"
      },
      :end_time       => "",
      :start_time     => ""
    }
    @venue = mock_model(Venue)
    @event = mock_model(Event, {
      :title          => "MyEvent",
      :start_time=    => true,
      :end_time=      => true,
    })
  end

  describe "when creating events" do
    it "should display form for creating new event" do
      get "new"
      response.should be_success
      response.should render_template(:new)
    end

    it "should create a new event without a venue" do
      Event.should_receive(:new).with(@params[:event]).and_return(@event)
      @event.stub!(:associate_with_venue).with(@params[:venue_name])
      @event.stub!(:venue).and_return(nil)
      @event.should_receive(:save).and_return(true)

      post "create", @params
      response.should redirect_to(event_path(@event))
    end

    it "should create a new event for an existing venue" do
      @params[:venue_name] = "Old Venue"
      Event.should_receive(:new).with(@params[:event]).and_return(@event)
      @event.stub!(:associate_with_venue).with(@params[:venue_name])
      @event.stub!(:venue).and_return(@venue)
      @event.should_receive(:save).and_return(true)
      @venue.stub!(:new_record?).and_return(false)

      post "create", @params
      response.should redirect_to(event_path(@event))
    end

    it "should create a new event and new venue, and redirect to venue edit form" do
      @params[:venue_name] = "New Venue"
      Event.should_receive(:new).with(@params[:event]).and_return(@event)
      @event.stub!(:associate_with_venue).with(@params[:venue_name])
      @event.stub!(:venue).and_return(@venue)
      @event.should_receive(:save).and_return(true)
      @venue.stub!(:new_record?).and_return(true)

      post "create", @params
      response.should redirect_to(edit_venue_url(@venue, :from_event => @event.id))
    end

    it "should catch errors and redisplay the new event form" do
      post "create"
      response.should render_template(:new)
    end

    it "should stop evil robots" do
      post "create", :trap_field => "I AM AN EVIL ROBOT, I EAT OLD PEOPLE'S MEDICINE FOR FOOD!"
      response.should render_template(:new)
      flash[:failure].should match(/evil robot/i)
    end
  end

  describe "when updating events" do
    it "should display form for editing event" do
      Event.should_receive(:find).and_return(@event)

      get "edit", :id => 1
      response.should be_success
      response.should render_template(:edit)
    end

    it "should update an event without a venue" do
      Event.should_receive(:find).and_return(@event)
      @event.stub!(:associate_with_venue).with(@params[:venue_name])
      @event.stub!(:venue).and_return(nil)
      @event.should_receive(:update_attributes).and_return(true)

      put "update", @params
      response.should redirect_to(event_path(@event))
    end

    it "should update an event and associate it with an existing venue" do
      @params[:venue_name] = "Old Venue"
      Event.should_receive(:find).and_return(@event)
      @event.stub!(:associate_with_venue).with(@params[:venue_name])
      @event.stub!(:venue).and_return(@venue)
      @event.should_receive(:update_attributes).and_return(true)
      @venue.stub!(:new_record?).and_return(false)

      put "update", @params
      response.should redirect_to(event_path(@event))
    end

    it "should update an event and create a new venue, and redirect to the venue edit form" do
      @params[:venue_name] = "New Venue"
      Event.should_receive(:find).and_return(@event)
      @event.stub!(:associate_with_venue).with(@params[:venue_name])
      @event.stub!(:venue).and_return(@venue)
      @event.should_receive(:update_attributes).and_return(true)
      @venue.stub!(:new_record?).and_return(true)

      put "update", @params
      response.should redirect_to(edit_venue_url(@venue, :from_event => @event.id))
    end

    it "should catch errors and redisplay the new event form" do
      Event.should_receive(:find).and_return(@event)
      @event.stub!(:associate_with_venue)
      @event.stub!(:venue).and_return(nil)
      @event.should_receive(:update_attributes).and_return(false)

      post "update", :id => 1234
      response.should render_template(:edit)
    end

  end
end

describe EventsController, "managing duplicates" do
  integrate_views
  fixtures :events, :venues

  it "should find new duplicates and not old duplicates" do
    get 'duplicates'

    # New duplicates
    web3con = assigns[:grouped_events].select{|keys,values| keys.include?("Web 3.0 Conference")}
    web3con.should_not be_blank
    web3con.first.last.size.should == 2

    # Old duplicates
    web1con = assigns[:grouped_events].select{|keys,values| keys.include?("Web 1.0 Conference")}
    web1con.should be_blank
  end

  it "should redirect duplicate events to their master" do
    event_master = events(:calagator_codesprint)
    event_duplicate = events(:tomorrow)

    get 'show', :id => event_duplicate.id
    response.should_not be_redirect
    assigns(:event).id.should == event_duplicate.id

    event_duplicate.duplicate_of = event_master
    event_duplicate.save!

    get 'show', :id => event_duplicate.id
    response.should be_redirect
    response.should redirect_to(event_url(event_master.id))
  end

end

describe EventsController, "when searching" do

  it "should search" do
    Event.should_receive(:search_grouped_by_currentness).and_return({:current => [], :past => []})

    post :search, :query => "myquery"
  end

  it "should fail if given no search query" do
    post :search

    flash[:failure].should_not be_blank
    response.should redirect_to(root_path)
  end

end

describe EventsController, "when deleting" do

  it "should destroy events" do
    event = mock_model(Event)
    event.should_receive(:destroy)
    Event.should_receive(:find).and_return(event)

    delete 'destroy', :id => 1234
    response.should redirect_to(events_url)
  end

end
