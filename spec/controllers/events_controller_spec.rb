require File.dirname(__FILE__) + '/../spec_helper'

describe EventsController do
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
      @event.should_receive(:associate_with_venue).with(@params[:venue_name])
      @event.should_receive(:venue).and_return(nil)
      @event.should_receive(:save).and_return(true)

      post "create", @params
      response.should redirect_to(event_path(@event))
    end

    it "should create a new event for an existing venue" do
      @params[:venue_name] = "Old Venue"
      Event.should_receive(:new).with(@params[:event]).and_return(@event)
      @event.should_receive(:associate_with_venue).with(@params[:venue_name])
      @event.should_receive(:venue).any_number_of_times.and_return(@venue)
      @event.should_receive(:save).and_return(true)
      @venue.should_receive(:new_record?).and_return(false)

      post "create", @params
      response.should redirect_to(event_path(@event))
    end

    it "should create a new event and new venue, and redirect to venue edit form" do
      @params[:venue_name] = "New Venue"
      Event.should_receive(:new).with(@params[:event]).and_return(@event)
      @event.should_receive(:associate_with_venue).with(@params[:venue_name])
      @event.should_receive(:venue).any_number_of_times.and_return(@venue)
      @event.should_receive(:save).and_return(true)
      @venue.should_receive(:new_record?).and_return(true)

      post "create", @params
      response.should redirect_to(edit_venue_url(@venue, :from_event => @event.id))
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
      @event.should_receive(:associate_with_venue).with(@params[:venue_name])
      @event.should_receive(:venue).and_return(nil)
      @event.should_receive(:update_attributes).and_return(true)

      put "update", @params
      response.should redirect_to(event_path(@event))
    end

    it "should update an event and associate it with an existing venue" do
      @params[:venue_name] = "Old Venue"
      Event.should_receive(:find).and_return(@event)
      @event.should_receive(:associate_with_venue).with(@params[:venue_name])
      @event.should_receive(:venue).any_number_of_times.and_return(@venue)
      @event.should_receive(:update_attributes).and_return(true)
      @venue.should_receive(:new_record?).and_return(false)

      put "update", @params
      response.should redirect_to(event_path(@event))
    end

    it "should update an event and create a new venue, and redirect to the venue edit form" do
      @params[:venue_name] = "New Venue"
      Event.should_receive(:find).and_return(@event)
      @event.should_receive(:associate_with_venue).with(@params[:venue_name])
      @event.should_receive(:venue).any_number_of_times.and_return(@venue)
      @event.should_receive(:update_attributes).and_return(true)
      @venue.should_receive(:new_record?).and_return(true)

      put "update", @params
      response.should redirect_to(edit_venue_url(@venue, :from_event => @event.id))
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

describe EventsController, "search" do

  it "should perform searches" do
    Event.should_receive(:search_grouped_by_currentness).and_return({:current => [], :past => []})
    post :search, :query => "myquery"
  end

end
