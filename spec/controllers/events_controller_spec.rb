require 'spec_helper'
require './spec/controllers/squash_many_duplicates_examples'

describe EventsController do
  describe "#index" do
    render_views

    describe "as HTML" do
      it "should produce HTML" do
        get :index, :format => "html"

        response.body.should have_selector "table.event_table"
      end
    end

    describe "as XML" do
      describe "without events" do
        before do
          get :index, :format => "xml"

          @struct = Hash.from_xml(response.body)["events"]
        end

        it "should not have entries" do
          @struct.should be_blank
        end
      end

      describe "with events" do
        before do
          FactoryGirl.create(:event_with_venue)
          FactoryGirl.create(:event_with_venue)

          get :index, :format => "xml"

          @struct = Hash.from_xml(response.body)["events"]
        end

        it "should return an array" do
          @struct.should be_a_kind_of Array
        end

        it "should have entries" do
          @struct.should be_present
        end

        it "should include venue details" do
          event = @struct.first
          venue = event["venue"]
          venue_title = venue["title"]  # Why XML? Why?
          venue_title.should be_a_kind_of String
          venue_title.should be_present
        end
      end
    end

    describe "as JSON" do
      it "should accept a JSONP callback" do
        post :index, :format => "json", :callback => "some_function"

        response.body.split("\n").join.should match /^\s*some_function\(.*\);?\s*$/
      end

      describe "without events" do
        before do
          post :index, :format => "json"

          @struct = ActiveSupport::JSON.decode(response.body)
        end

        it "should return an array" do
          @struct.should be_a_kind_of Array
        end

        it "should not have entries" do
          @struct.should be_empty
        end
      end

      describe "with events" do
        before do
          @event = FactoryGirl.create(:event_with_venue)
          @venue = @event.venue

          post :index, :format => "json"

          @struct = ActiveSupport::JSON.decode(response.body)
        end

        it "should return an array" do
          @struct.should be_a_kind_of Array
        end

        it "should return an event" do
          event = @struct.first
          event['id'].should eq @event.id
          event['title'].should eq @event.title
        end

        it "should return an event's venue" do
          event = @struct.first
          venue = event['venue']

          venue['id'].should eq @venue.id
          venue['title'].should eq @venue.title
        end
      end
    end

    describe "as ATOM" do
      describe "without events" do
        before do
          post :index, :format => "atom"
          @struct = Hash.from_xml(response.body)
        end

        it "should be a feed" do
          @struct['feed']['xmlns'].should be_present
        end

        it "should not have events" do
          @struct['feed']['entry'].should be_blank
        end
      end

      describe "with events" do
        before do
          FactoryGirl.create(:event_with_venue)
          FactoryGirl.create(:event_with_venue)

          post :index, :format => "atom"

          @struct = Hash.from_xml(response.body)
        end

        let(:entries) { @struct["feed"]["entry"] }

        it "should be a feed" do
          @struct['feed']['xmlns'].should be_present
        end

        it "should have entries" do
          entries.should be_present
        end

        it "should have an event" do
          entry = entries.first
          record = Event.find(entry['id'][%r{(\d+)$}, 1])

          Nokogiri.parse(entry['content']).search('.description p').inner_html.should eq record.description
          entry['end_time'].should eq record.end_time.xmlschema
          entry['start_time'].should eq record.start_time.xmlschema
          entry['summary'].should be_present
          entry['title'].should eq record.title
          entry['updated'].should eq record.updated_at.xmlschema
          entry['url'].should eq event_url(record)
        end
      end
    end

    describe "as iCalendar" do
      describe "without events" do
        before do
          post :index, :format => "ics"
        end

        it "should have a calendar" do
          response.body.should match /BEGIN:VCALENDAR/
        end

        it "should not have events" do
          response.body.should_not match /BEGIN:VEVENT/
        end
      end

      describe "with events" do
        before do
          @current_event = FactoryGirl.create(:event, :start_time => today + 1.hour)
          @past_event = FactoryGirl.create(:event, :start_time => today - 1.hour)

          post :index, :format => "ics"
        end

        it "should have a calendar" do
          response.body.should match /BEGIN:VCALENDAR/
        end

        it "should have events" do
          response.body.should match /BEGIN:VEVENT/
        end

        it "should render all future events" do
          response.body.should match /SUMMARY:#{@current_event.title}/
        end

        it "should not render past events" do
          response.body.should_not =~ /SUMMARY:#{@past_event.title}/
        end
      end
    end

    describe "and filtering by date range" do
      [:start, :end].each do |date_kind|
        describe "for #{date_kind} date" do
          let(:start_date) { Date.parse("2010-01-01") }
          let(:end_date) { Date.parse("2010-04-01") }
          let(:date_field) { "#{date_kind}_date" }

          around do |example|
            Timecop.freeze(start_date) do
              example.run
            end
          end

          it "should use the default if not given the parameter" do
            get :index, :date => {}
            assigns[date_field].should eq send(date_field)
            flash[:failure].should be_nil
          end

          it "should use the default if given a malformed parameter" do
            get :index, :date => "omgkittens"
            assigns[date_field].should eq send(date_field)
            response.body.should have_selector(".flash_failure", text: 'malformed')
          end

          it "should use the default if given a missing parameter" do
            get :index, :date => {:foo => "bar"}
            assigns[date_field].should eq send(date_field)
            response.body.should have_selector(".flash_failure", text: 'missing')
          end

          it "should use the default if given an empty parameter" do
            get :index, :date => {date_kind => ""}
            assigns[date_field].should eq send(date_field)
            response.body.should have_selector(".flash_failure", text: 'empty')
          end

          it "should use the default if given an invalid parameter" do
            get :index, :date => {date_kind => "omgkittens"}
            assigns[date_field].should eq send(date_field)
            response.body.should have_selector(".flash_failure", text: 'invalid')
          end

          it "should use the value if valid" do
            expected = Date.yesterday
            get :index, :date => {date_kind => expected.to_s("%Y-%m-%d")}
            assigns[date_field].should eq expected
          end
        end
      end

      it "should return matching events" do
        # Given
        matching = [
          Event.create!(
            :title => "matching1",
            :start_time => Time.zone.parse("2010-01-16 00:00"),
            :end_time => Time.zone.parse("2010-01-16 01:00")
          ),
          Event.create!(:title => "matching2",
            :start_time => Time.zone.parse("2010-01-16 23:00"),
            :end_time => Time.zone.parse("2010-01-17 00:00")
          ),
        ]

        non_matching = [
          Event.create!(
            :title => "nonmatchingbefore",
            :start_time => Time.zone.parse("2010-01-15 23:00"),
            :end_time => Time.zone.parse("2010-01-15 23:59")
          ),
          Event.create!(
            :title => "nonmatchingafter",
            :start_time => Time.zone.parse("2010-01-17 00:01"),
            :end_time => Time.zone.parse("2010-01-17 01:00")
          ),
        ]

        # When
        get :index, :date => {:start => "2010-01-16", :end => "2010-01-16"}
        results = assigns[:events]

        # Then
        results.size.should eq 2
        results.should eq matching
      end
    end
  end

  describe "#show" do
    it "should show an event" do
      event = Event.new(:start_time => now)
      Event.should_receive(:find).and_return(event)

      get "show", :id => 1234
      response.should be_success
    end

    it "should redirect from a duplicate event to its master" do
      master = FactoryGirl.create(:event, id: 4321)
      event = Event.new(:start_time => now, :duplicate_of => master)
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

  describe "when creating and updating events" do
    before do
      @params = {
        "end_date"       => "2008-06-04",
        "start_date"     => "2008-06-03",
        "event" => {
          "title"       => "MyVenue",
          "url"         => "http://my.venue",
          "description" => "Wheeeee"
        },
        "end_time"       => "",
        "start_time"     => ""
      }.with_indifferent_access
      @venue = FactoryGirl.build(:venue)
      @event = FactoryGirl.build(:event, :venue => @venue)
    end

    describe "#new" do
      it "should display form for creating new event" do
        get "new"
        response.should be_success
        response.should render_template :new
      end
    end

    describe "#create" do
      render_views

      it "should create a new event without a venue" do
        @params[:event][:venue_id] = nil
        post "create", @params
        @event = Event.find_by_title(@params[:event][:title])
        response.should redirect_to(@event)
      end

      it "should associate a venue based on a given venue id" do
        @venue.save!
        @params[:event][:venue_id] = @venue.id.to_s
        post "create", @params
        @event = Event.find_by_title(@params[:event][:title])
        @event.venue.should == @venue
        response.should redirect_to(@event)
      end

      it "should associate a venue based on a given venue name" do
        @venue.save!
        @params[:venue_name] = @venue.title
        post "create", @params
        @event = Event.find_by_title(@params[:event][:title])
        @event.venue.should == @venue
        response.should redirect_to(@event)
      end

      it "should associate a venue by id when both an id and a name are provided" do
        @venue.save!
        @venue2 = FactoryGirl.create(:venue)
        @params[:event][:venue_id] = @venue.id.to_s
        @params[:venue_name] = @venue2.title
        post "create", @params
        @event = Event.find_by_title(@params[:event][:title])
        @event.venue.should == @venue
        response.should redirect_to(@event)
      end

      it "should create a new event and new venue, and redirect to venue edit form" do
        @params[:venue_name] = "New Venue"
        post "create", @params
        @event = Event.find_by_title(@params[:event][:title])
        @venue = Venue.find_by_title("New Venue")
        @event.venue.should == @venue
        response.should redirect_to(edit_venue_url(@venue, :from_event => @event.id))
      end

      it "should catch errors and redisplay the new event form" do
        post "create"
        response.should render_template :new
      end

      it "should stop evil robots" do
        post "create", :trap_field => "I AM AN EVIL ROBOT, I EAT OLD PEOPLE'S MEDICINE FOR FOOD!"
        response.should render_template :new
        flash[:failure].should match /evil robot/i
      end

      it "should not allow too many links in the description" do
        @params[:event][:description] = <<-DESC
          http://example.com
          https://example.com
          http://example.net
          https://example.net
        DESC
        post "create", @params
        response.should render_template :new
        flash[:failure].should match /too many links/i
      end

      it "should accept HTTP-rich presentation descriptions without too many links" do
        @params[:event][:description] = <<-DESC
          I hereby offer to give a presentation at the August ruby meeting about the faraday
          gem (https://github.com/lostisland/faraday) and how compares to or compliments other
          HTTP client libraries such as httparty (https://github.com/jnunemaker/httparty).

          --

          I wouldn't mind seeing a PDX.pm talk about HTTP::Tiny vs Net::HTTP::Tiny vs Net::HTTP
          vs HTTP::Client vs HTTP::Client::Parallel
        DESC
        post "create", @params
        flash[:failure].should be_nil
      end

      it "should allow the user to preview the event" do
        @params[:preview] = "Preview"
        post "create", @params
        response.should render_template :new
        response.body.should have_selector '#event_preview'
      end

      it "should create an event for an existing venue" do
        venue = FactoryGirl.create(:venue)

        post "create",
          :start_time => now.strftime("%Y-%m-%d"),
          :end_time   => (now + 1.hour).strftime("%Y-%m-%d"),
          :event      => {
            :title      => "My Event",
            :tag_list   => ",,foo,bar, baz,",
          },
          :venue_name => venue.title

        response.should be_redirect

        flash[:success].should be_present

        event = assigns[:event]
        event.title.should eq "My Event"
        event.venue.title.should eq venue.title
        event.venue.id.should eq venue.id
        event.tag_list.to_a.sort.should eq %w[bar baz foo]
      end
    end

    describe "#update" do
      before(:each) do
        @event = FactoryGirl.create(:event_with_venue, id: 42)
        @venue = @event.venue
        @params.merge!(id: 42)
      end

      it "should display form for editing event" do
        get "edit", id: 42
        response.should be_success
        response.should render_template :edit
      end

      it "should update an event without a venue" do
        @event.venue = nil
        put "update", @params
        response.should redirect_to(@event)
      end

      it "should associate a venue based on a given venue id" do
        @venue = FactoryGirl.create(:venue)
        @params[:event][:venue_id] = @venue.id.to_s
        put "update", @params
        @event.reload.venue.should == @venue
        response.should redirect_to(@event)
      end

      it "should associate a venue based on a given venue name" do
        @venue = FactoryGirl.create(:venue)
        @params[:venue_name] = @venue.title
        put "update", @params
        @event.reload.venue.should == @venue
        response.should redirect_to(@event)
      end

      it "should associate a venue by id when both an id and a name are provided" do
        @venue = FactoryGirl.create(:venue)
        @venue2 = FactoryGirl.create(:venue)
        @params[:event][:venue_id] = @venue.id.to_s
        @params[:venue_name] = @venue2.title
        put "update", @params
        @event.reload.venue.should == @venue
        response.should redirect_to(@event)
      end

      it "should update an event and create a new venue, and redirect to the venue edit form" do
        @params[:venue_name] = "New Venue"
        put "update", @params
        @venue = Venue.find_by_title("New Venue")
        response.should redirect_to(edit_venue_url(@venue, :from_event => @event.id))
      end

      it "should catch errors and redisplay the new event form" do
        @params[:event][:title] = nil
        put "update", @params
        response.should render_template :edit
      end

      it "should stop evil robots" do
        @params[:trap_field] = "I AM AN EVIL ROBOT, I EAT OLD PEOPLE'S MEDICINE FOR FOOD!"
        put "update", @params
        response.should render_template :edit
        flash[:failure].should match /evil robot/i
      end

      it "should not allow too many links in the description" do
        @params[:event][:description] = <<-DESC
          http://example.com
          https://example.com
          http://example.net
          https://example.net
        DESC
        put "update", @params
        response.should render_template :edit
        flash[:failure].should match /too many links/i
      end

      it "should allow the user to preview the event" do
        put "update", @params.merge(:preview => "Preview")
        response.should render_template :edit
      end
    end

    describe "#clone" do
      before do
        @event = FactoryGirl.create(:event)

        Event.stub(:find).and_return(@event)

        get "clone", :id => 1
      end

      it "should build an unsaved record" do
        record = assigns[:event]
        record.should be_a_new_record
        record.id.should be_nil
      end

      it "should build a cloned record similar to the existing record" do
        record = assigns[:event]
        %w[title description venue_id venue_details].each do |field|
          record.attributes[field].should eq @event.attributes[field]
        end
      end

      it "should display a new event form" do
        response.should be_success
        response.should render_template :new
      end

      it "should have notice with cloning instructions" do
        flash[:success].should match /clone/i
      end
    end
  end

  describe "#duplicates" do
    render_views

    it "should find current duplicates and not past duplicates" do
      current_master = FactoryGirl.create(:event, :title => "Current")
      current_duplicate = FactoryGirl.create(:event, :title => current_master.title)

      past_master = FactoryGirl.create(:event, :title => "Past", :start_time => now - 2.days)
      past_duplicate = FactoryGirl.create(:event, :title => past_master.title, :start_time => now - 1.day)

      get 'duplicates', :type => 'title'

      # Current duplicates
      assigns[:grouped_events].select{|keys,values| keys.include?(current_master.title)}.tap do |events|
        events.should_not be_empty
        events.first.last.size.should eq 2
      end

      # Past duplicates
      assigns[:grouped_events].select{|keys,values| keys.include?(past_master.title)}.should be_empty
    end

    it "should redirect duplicate events to their master" do
      event_master = FactoryGirl.create(:event)
      event_duplicate = FactoryGirl.create(:event)

      get 'show', :id => event_duplicate.id
      response.should_not be_redirect
      assigns(:event).id.should eq event_duplicate.id

      event_duplicate.duplicate_of = event_master
      event_duplicate.save!

      get 'show', :id => event_duplicate.id
      response.should be_redirect
      response.should redirect_to(event_url(event_master.id))
    end

    it "should display an error message if given invalid arguments" do
      get 'duplicates', :type => 'omgwtfbbq'

      response.should be_success
      response.body.should have_selector('.failure', text: 'omgwtfbbq')
    end
  end

  context do
    include_examples "#squash_many_duplicates", :event
  end

  describe "#search" do
    describe "when returning results" do
      render_views

      let!(:current_event) { FactoryGirl.create(:event_with_venue, title: "MyQuery") }
      let!(:current_event_2) { FactoryGirl.create(:event_with_venue, description: "WOW myquery!") }
      let!(:past_event) { FactoryGirl.create(:event_with_venue, title: "old myquery") }

      describe "in HTML format" do
        before do
          post :search, :query => "myquery", :format => "html"
        end

        it "should assign search result" do
          assigns[:search].should be_a Event::Search
        end

        it "should assign matching events" do
          assigns[:events].should =~ [current_event, current_event_2, past_event]
        end

        it "should render matching events" do
          have_selector "table.event_table" do
            have_selector ".vevent a.summary", :href => event_url(results[:past])
            have_selector ".vevent a.summary", :href => event_url(results[:current])
          end
        end

        describe "sidebar" do
          it "should have iCalendar feed" do
            have_selector ".sidebar a", :href => search_events_url(:query => @query, :format => "ics", :protocol => "webcal")
          end

          it "should have Atom feed" do
            have_selector ".sidebar a", :href => search_events_url(:query => @query, :format => "atom")
          end

          it "should have Google subscription" do
            ics_url = search_events_url(query: @query, format: 'ics')
            google_url = "https://www.google.com/calendar/render?cid=#{ics_url}"
            have_selector ".sidebar a", href: google_url
          end
        end
      end

      describe "in XML format" do
        it "should produce XML" do
          post :search, :query => "myquery", :format => "xml"

          hash = Hash.from_xml(response.body)
          hash["events"].should be_a_kind_of Array
        end

        it "should include venue details" do
          post :search, :query => "myquery", :format => "xml"

          hash = Hash.from_xml(response.body)
          event = hash["events"].first
          venue = event["venue"]
          venue_title = venue["title"]
          venue_title.should be_a_kind_of String
          venue_title.length.should be_present
        end
      end

      describe "in JSON format" do
        it "should produce JSON" do
          post :search, :query => "myquery", :format => "json"

          struct = ActiveSupport::JSON.decode(response.body)
          struct.should be_a_kind_of Array
        end

        it "should accept a JSONP callback" do
          post :search, :query => "myquery", :format => "json", :callback => "some_function"

          response.body.should match /^\s*some_function\(.*\);?\s*$/
        end

        it "should include venue details" do
          post :search, :query => "myquery", :format => "json"

          struct = ActiveSupport::JSON.decode(response.body)
          event = struct.first
          event["venue"]["title"].should be_a_kind_of String
          event["venue"]["title"].length.should be_present
        end
      end

      describe "in ATOM format" do
        it "should produce ATOM" do
          post :search, :query => "myquery", :format => "atom"

          hash = Hash.from_xml(response.body)
          hash["feed"]["entry"].should be_a_kind_of Array
        end
      end

      describe "in ICS format" do
        it "should produce ICS" do
          post :search, :query => "myquery", :format => "ics"

          response.body.should match /BEGIN:VEVENT/
        end

        it "should produce events matching the query" do
          post :search, :query => "myquery", :format => "ics"
          response.body.should match /SUMMARY:#{current_event_2.title}/
          response.body.should match /SUMMARY:#{past_event.title}/
        end
      end

      describe "failures" do
        it "sets search failures in the flash message" do
          Event::Search.any_instance.stub failure_message: "OMG"
          post :search
          flash[:failure].should == "OMG"
        end

        it "redirects to home if hard failure" do
          Event::Search.any_instance.stub hard_failure?: true
          post :search
          response.should redirect_to(root_path)
        end
      end
    end
  end

  describe "#destroy" do
    it "should destroy events" do
      event = FactoryGirl.build(:event)
      event.should_receive(:destroy)
      Event.should_receive(:find).and_return(event)

      delete 'destroy', :id => 1234
      response.should redirect_to(events_url)
    end
  end
end
