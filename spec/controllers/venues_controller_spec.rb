require 'spec_helper'
require './spec/controllers/squash_many_duplicates_examples'

describe VenuesController do
  render_views

  it "should redirect duplicate venues to their master" do
    venue_master = FactoryGirl.create(:venue)
    venue_duplicate = FactoryGirl.create(:venue)

    # No redirect when they're unique
    get 'show', :id => venue_duplicate.id
    response.should_not be_redirect
    assigns(:venue).id.should eq venue_duplicate.id

    # Mark as duplicate
    venue_duplicate.duplicate_of = venue_master
    venue_duplicate.save!

    # Now check that redirection happens
    get 'show', :id => venue_duplicate.id
    response.should be_redirect
    response.should redirect_to(venue_url(venue_master.id))
  end

  it "should display an error message if given invalid arguments" do
    get 'duplicates', :type => 'omgwtfbbq'

    response.should be_success
    response.body.should have_selector('.failure', text: 'omgwtfbbq')
  end

  context do
    include_examples "#squash_many_duplicates", :venue
  end

  describe "when creating venues" do
    it "should redirect to the newly created venue" do
      post :create, venue: FactoryGirl.attributes_for(:venue)
      response.should redirect_to(assigns(:venue))
    end

    it "should stop evil robots" do
      post :create, :trap_field => "I AM AN EVIL ROBOT, I EAT OLD PEOPLE'S MEDICINE FOR FOOD!"
      response.should render_template :new
    end
  end

  describe "when updating venues" do
    before do
      @venue = FactoryGirl.create(:venue)
    end

    it "should redirect to the updated venue" do
      put :update, id: @venue.id, venue: FactoryGirl.attributes_for(:venue)
      response.should redirect_to(@venue)
    end

    it "should redirect to any associated event" do
      @event = FactoryGirl.create(:event, venue: @venue)
      put :update, id: @venue.id, from_event: @event.id, venue: FactoryGirl.attributes_for(:venue)
      response.should redirect_to(@event)
    end

    it "should stop evil robots" do
      put :update, id: @venue.id, trap_field: "I AM AN EVIL ROBOT, I EAT OLD PEOPLE'S MEDICINE FOR FOOD!"
      response.should render_template :edit
    end
  end

  describe "when rendering the new venue page" do
    it "passes the template a new venue" do
      get :new
      assigns[:venue].should be_a Venue
      assigns[:venue].should be_new_record
    end
  end

  describe "when rendering the edit venue page" do
    it "passes the template the specified venue" do
      @venue = FactoryGirl.create(:venue)
      get :edit, id: @venue.id
      assigns[:venue].should == @venue
    end
  end

  describe "when rendering the map page" do
    before do
      @open_venue = FactoryGirl.create(:venue)
      @closed_venue = FactoryGirl.create(:venue, closed: true)
      @duplicate_venue = FactoryGirl.create(:venue, duplicate_of: @open_venue)
    end

    it "only shows open non-duplicate venues" do
      get :map
      assigns[:venues].should == [@open_venue]
    end
  end

  describe "when rendering the venues index" do
    before do
      @venues = [FactoryGirl.create(:venue), FactoryGirl.create(:venue)]
    end

    it "should assign the search object to @search" do
      get :index
      assigns[:search].should be_a Venue::Search
    end

    it "should assign search results to @venues" do
      get :index
      assigns[:venues].should == @venues
    end

    describe "in JSON format" do
      it "should produce JSON" do
        get :index, :format => "json"

        struct = ActiveSupport::JSON.decode(response.body)
        struct.should be_a_kind_of Array
      end

      it "should accept a JSONP callback" do
        get :index, :format => "json", :callback => "some_function"

        response.body.split("\n").join.should match /^\s*some_function\(.*\);?\s*$/
      end
    end

  end

  describe "when showing venues" do
    it "redirects to all venues if venue doesn't exist" do
      get :show, id: "garbage"
      response.should redirect_to("/venues")
    end

    describe "in JSON format" do
      describe "with events" do
        before do
          @venue = FactoryGirl.build(:venue, :id => 123)
          Venue.stub(:find).and_return(@venue)
        end

        it "should produce JSON" do
          get :show, :id => @venue.to_param, :format => "json"

          struct = ActiveSupport::JSON.decode(response.body)
          struct.should be_a_kind_of Hash
          %w[id title description address].each do |field|
            struct[field].should eq @venue.send(field)
          end
        end

        it "should accept a JSONP callback" do
          get :show, :id => @venue.to_param, :format => "json", :callback => "some_function"

          response.body.split("\n").join.should match /^\s*some_function\(.*\);?\s*$/
        end
      end
    end

    describe "in HTML format" do
      describe "venue with future and past events" do
        before do
          @venue = FactoryGirl.create(:venue)
          @future_event = FactoryGirl.create(:event, :venue => @venue)
          @past_event = FactoryGirl.create(:event, :venue => @venue,
            :start_time => Time.now - 1.week + 1.hour,
            :end_time => Time.now - 1.week + 2.hours)

          get :show, :id => @venue.to_param, :format => "html"
          response.should be_success
        end

        it "should have a venue" do
          response.body.should have_selector(".location .fn", text: @venue.title)
        end

        it "should have a future event" do
          response.body.should have_selector("#events #future_events .summary", text: @future_event.title)
        end

        it "should have a past event" do
          response.body.should have_selector("#events #past_events .summary", text: @past_event.title)
        end
      end
    end

    describe "as an iCalendar" do
      before do
        @venue = FactoryGirl.create(:venue)
        @future_event = FactoryGirl.create(:event, :venue => @venue, :start_time => today + 1.hour)
        @past_event = FactoryGirl.create(:event, :venue => @venue, :start_time => today - 1.hour)

        get :show, :id => @venue.to_param, :format => "ics"
      end

      it "should have a calendar" do
        response.body.should match /BEGIN:VCALENDAR/
      end

      it "should have events" do
        response.body.should match /BEGIN:VEVENT/
      end

      it "should render all future events" do
        response.body.should match /SUMMARY:#{@future_event.title}/
      end

      it "should render all past events" do
        response.body.should match /SUMMARY:#{@past_event.title}/
      end
    end

  end

  describe "DELETE" do
    describe "when deleting a venue without events" do
      before do
        @venue = FactoryGirl.create(:venue)
      end

      shared_examples_for "destroying a Venue record without events" do
        it "should destroy the Venue record" do
          lambda { Venue.find(@venue.id) }.should raise_error ActiveRecord::RecordNotFound
        end
      end

      describe "and rendering HTML" do
        before do
          delete :destroy, :id => @venue.id
        end

        it_should_behave_like "destroying a Venue record without events"

        it "should display a success message" do
          flash[:success].should be_present
        end

        it "should redirect to the venues listing" do
          response.should redirect_to(venues_path)
        end
      end

      describe "and rendering XML" do
        render_views

        before do
          delete :destroy, :id => @venue.id, :format => "xml"
        end

        it_should_behave_like "destroying a Venue record without events"

        it "should return a success status" do
          response.should be_success
        end
      end
    end

    describe "when deleting a venue with events" do
      before do
        @event = FactoryGirl.create(:event_with_venue)
        @venue = @event.venue
      end

      shared_examples_for "destroying a Venue record with events" do
        it "should not destroy the Venue record" do
          Venue.find(@venue.id).should be_present
        end
      end

      describe "and rendering HTML" do
        before do
          delete :destroy, :id => @venue.id
        end

        it_should_behave_like "destroying a Venue record with events"

        it "should display a failure message" do
          flash[:failure].should be_present
        end

        it "should redirect to the venue page" do
          response.should redirect_to(venue_path(@venue))
        end
      end

      describe "and rendering XML" do
        before do
          delete :destroy, :id => @venue.id, :format => "xml"
        end

        it_should_behave_like "destroying a Venue record with events"

        it "should return unprocessable entity status" do
          response.code.to_i.should eq 422
        end

        it "should describing the problem" do
          response.body.should match /cannot/i
        end
      end
    end
  end
end
