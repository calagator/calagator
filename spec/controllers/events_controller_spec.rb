require File.dirname(__FILE__) + '/../spec_helper'

describe EventsController, "when displaying index" do
  integrate_views
  fixtures :events, :venues

  it "should produce HTML" do
    get :index, :format => "html"

    response.should have_tag("table.event_table")
  end

  describe "in XML format" do

    it "should produce XML" do
      post :index, :format => "xml"

      struct = XmlSimple.xml_in_string(response.body)
      struct["event"].should be_a_kind_of(Array)
    end

    it "should include venue details" do
      post :index, :format => "xml"

      struct = XmlSimple.xml_in_string(response.body)
      event = struct["event"].first
      venue = event["venue"].first
      venue_title = venue["title"].first  # Why XML? Why?
      venue_title.should be_a_kind_of(String)
      venue_title.length.should > 0
    end

  end

  describe "in JSON format" do

    it "should produce JSON" do
      post :index, :format => "json"

      struct = ActiveSupport::JSON.decode(response.body)
      struct.should be_a_kind_of(Array)
    end

    it "should accept a JSONP callback" do
      post :index, :format => "json", :callback => "some_function"

      response.body.split("\n").join.should match(/^\s*some_function\(.*\);?\s*$/)
    end

    it "should include venue details" do
      post :index, :format => "json"

      struct = ActiveSupport::JSON.decode(response.body)
      event = struct.first
      event["venue"]["title"].should be_a_kind_of(String)
      event["venue"]["title"].length.should > 0
    end

  end

  it "should produce ATOM" do
    post :index, :format => "atom"

    struct = XmlSimple.xml_in_string(response.body)
    struct["entry"].should be_a_kind_of(Array)
  end

  describe "in ICS format" do

    it "should produce ICS" do
      post :index, :format => "ics"

      response.body.should have_text(/BEGIN:VEVENT/)
    end

    it "should render all future events" do
      post :index, :format => "ics"
      response.body.should =~ /SUMMARY:#{events(:tomorrow).title}/
      response.body.should_not =~ /SUMMARY:#{events(:old_event).title}/
    end

  end
end

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
    before(:each) do
      @event = mock_model(Event, {
        :title          => "MyEvent",
        :start_time=    => true,
        :end_time=      => true,
        :associate_with_venue => true,
        :venue => @venue
      })
      Event.stub!(:find).and_return(@event)
    end

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

    it "should stop evil robots" do
      put "update", :id => 1234, :trap_field => "I AM AN EVIL ROBOT, I EAT OLD PEOPLE'S MEDICINE FOR FOOD!"
      response.should render_template(:edit)
      flash[:failure].should match(/evil robot/i)
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

  it "should display an error message if given invalid arguments" do
    get 'duplicates', :type => 'omgwtfbbq'

    response.should be_success
    response.should have_tag('.failure', :text => /omgwtfbbq/)
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

  it "should be able to only return current events" do
    Event.should_receive(:search).with("myquery", :order => nil, :skip_old => true).and_return([])

    post :search, :query => "myquery", :current => "1"
  end

  it "should be able to only return events matching specific tag" do
    Event.should_receive(:tagged_with).with("foo", :current => false, :order => nil).and_return([])

    post :search, :tag => "foo"
  end

  it "should warn if user tries ordering tags by score" do
    Event.should_receive(:tagged_with).with("foo", :current => false, :order => nil).and_return([])

    post :search, :tag => "foo", :order => "score"
    flash[:failure].should_not be_blank
  end

  describe "when returning results" do
    integrate_views
    fixtures :events, :venues

    before do
      @results = {
        :current => [events(:calagator_codesprint), events(:tomorrow)],
        :past    => [events(:old_event)],
      }
      Event.should_receive(:search_grouped_by_currentness).and_return(@results)
    end

    it "should produce HTML" do
      post :search, :query => "myquery", :format => "html"

      response.should have_tag("table.event_table")
      assigns[:events].should == @results[:past] + @results[:current]
    end

    describe "in XML format" do

      it "should produce XML" do
        post :search, :query => "myquery", :format => "xml"

        struct = XmlSimple.xml_in_string(response.body)
        struct["event"].should be_a_kind_of(Array)
      end

      it "should include venue details" do
        post :search, :query => "myquery", :format => "xml"

        struct = XmlSimple.xml_in_string(response.body)
        event = struct["event"].first
        venue = event["venue"].first
        venue_title = venue["title"].first  # Why XML? Why?
        venue_title.should be_a_kind_of(String)
        venue_title.length.should > 0
      end

    end

    describe "in JSON format" do

      it "should produce JSON" do
        post :search, :query => "myquery", :format => "json"

        struct = ActiveSupport::JSON.decode(response.body)
        struct.should be_a_kind_of(Array)
      end

      it "should accept a JSONP callback" do
        post :search, :query => "myquery", :format => "json", :callback => "some_function"

        response.body.split("\n").join.should match(/^\s*some_function\(.*\);?\s*$/)
      end

      it "should include venue details" do
        post :search, :query => "myquery", :format => "json"

        struct = ActiveSupport::JSON.decode(response.body)
        event = struct.first
        event["venue"]["title"].should be_a_kind_of(String)
        event["venue"]["title"].length.should > 0
      end

    end

    it "should produce ATOM" do
      post :search, :query => "myquery", :format => "atom"

      struct = XmlSimple.xml_in_string(response.body)
      struct["entry"].should be_a_kind_of(Array)
    end

    describe "in ICS format" do

      it "should produce ICS" do
        post :search, :query => "myquery", :format => "ics"

        response.body.should have_text(/BEGIN:VEVENT/)
      end

      it "should produce events matching the query" do
        post :search, :query => "myquery", :format => "ics"
        response.body.should =~ /SUMMARY:#{events(:tomorrow).title}/
        response.body.should =~ /SUMMARY:#{events(:old_event).title}/
      end

    end
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

describe EventsController, "when running integration test" do
  integrate_views
  fixtures :events, :venues

  before(:each) do
    @venue         = venues(:cubespace)
    @event_params  = {
      :title       => "MyEvent#{$$}",
      :description => "Description",
      :start_time  => Time.today.strftime("%Y-%m-%d"),
      :end_time    => Time.today.strftime("%Y-%m-%d")
    }
  end

  it "should create event for existing venue" do
    post "create",
      :event      => @event_params,
      :venue_name => @venue.title

    flash[:success].should_not be_blank
    event = assigns[:event]
    event.title.should == @event_params[:title]
    event.venue.title.should == @venue.title
  end

  it "should create event for exsiting venue and add tags" do
    post "create",
      :event      => @event_params.merge(:tag_list => ",,foo,bar, baz,"),
      :venue_name => @venue.title

    flash[:success].should_not be_blank
    event = assigns[:event]
    event.tag_list.should == "bar, baz, foo"
  end
end
