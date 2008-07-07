require File.dirname(__FILE__) + '/../spec_helper'


describe EventsController do

  it "should create an event" do
    params = {
      :end_date       => "2008-06-04",
      :start_date     => "2008-06-03",
      :event => {
        "title"       => "Foo",
        "venue_id"    => "1",
        "url"         => "http://foo.com",
        "description" => "Wheeeee"
      },
      :venue_name     => "Old Venue",
      :end_time       => "",
      :start_time     => ""
    }
    venue = mock_model(Venue)
    event = mock_model(Event, {
      :venue_id       => 1,
      :venue          => venue,
      :start_time=    => true,
      :end_time=      => true,
    })
    Event.should_receive(:new).with(params[:event]).and_return(event)
    event.should_receive(:save).and_return(true)
    event.should_receive(:associate_with_venue).with(params[:venue_name])

    post 'create', params
    response.should redirect_to(event_path(event))
  end

  it "should create an event without a venue" do
    params = {
      :end_date       => "2008-06-04",
      :start_date     => "2008-06-03",
      :event => {
        "title"       => "Foo",
        "venue_id"    => "",
        "url"         => "http://foo.com",
        "description" => "Wheeeee"
      },
      :venue_name     => "",
      :end_time       => "",
      :start_time     => ""
    }
    venue = mock_model(Venue)
    event = mock_model(Event, {
      :venue_id     => nil,
      :venue=       => true,
      :venue        => venue,
      :start_time=  => true,
      :end_time=    => true,
    })
    Event.should_receive(:new).with(params[:event]).and_return(event)
    event.should_receive(:save).and_return(true)
    event.should_receive(:associate_with_venue).with(params[:venue_name])

    post 'create', params
    response.should redirect_to(event_path(event))
  end

  it "should create an event with a venue"

end

describe EventsController, "when updating event" do

  it "should update an event"

  it "should update an event without a venue" do
    params = {
      :end_date       => "2008-06-04",
      :end_time       => "",
      :event => {
        "title"       => "Foo",
        "venue_id"    => "",
        "url"         => "http://foo.com",
        "description" => "Wheeeee",
      },
      :id => 1,
      :start_date     => "2008-06-03",
      :start_time     => "",
      :venue_name     => "",
    }
    venue = mock_model(Venue)
    event = mock_model(Event, {
      :associate_with_venue => true,
      :end_time=         => true,
      :start_time=       => true,
      :update_attributes => true,
      :venue             => venue,
      :venue=            => true,
      :venue_id          => nil,
    })
    Event.stub!(:find).and_return(event)

    put "update", params
    response.should redirect_to(event_path(event))
  end

end

describe EventsController, "when changing venue" do

  it "should change the venue"

  it "should show event when changing to an existing venue"

  it "should create a new venue when changing to a nonexistent venue"

  it "should redirect to the new venue when changing to a nonexistent venue"

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
