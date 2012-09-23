require 'spec_helper'

describe VenuesController do
  render_views

  #Delete this example and add some real ones
  it "should use VenuesController" do
    controller.should be_an_instance_of VenuesController
  end

  it "should redirect duplicate venues to their master" do
    venue_master = Factory(:venue)
    venue_duplicate = Factory(:venue)

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
    response.should have_selector('.failure', :content => 'omgwtfbbq')
  end

  describe "when creating venues" do
    it "should stop evil robots" do
      post :create, :trap_field => "I AM AN EVIL ROBOT, I EAT OLD PEOPLE'S MEDICINE FOR FOOD!"
      response.should render_template :new
    end
  end

  describe "when updating venues" do
    before do
      @venue = Factory.build(:venue, :versions => [])
      Venue.stub!(:find).and_return(@venue)
    end

    it "should stop evil robots" do
      put :update,:id => '1', :trap_field => "I AM AN EVIL ROBOT, I EAT OLD PEOPLE'S MEDICINE FOR FOOD!"
      response.should render_template :edit
    end
  end

  describe "when rendering the venues index" do
    before do
      @open_venue = Factory(:venue, :title => 'Open Town', :description => 'baz', :wifi => false)
      @closed_venue = Factory(:venue, :title => 'Closed Down', :closed => true, :wifi => false)
      @wifi_venue = Factory(:venue, :title => "Internetful", :wifi => true)
    end

    describe "with no parameters" do
      before do
        get :index
      end

      it "should assign @most_active_venues and @newest_venues by default" do
        get :index
        assigns[:most_active_venues].should be_present
        assigns[:newest_venues].should be_present
      end

      it "should not included closed venues" do
        assigns[:newest_venues].should_not include @closed_venue
      end
    end

    describe "and showing all venues" do
      it "should include closed venues when asked to with the include_closed parameter" do
        get :index, :all => '1', :include_closed => '1'
        assigns[:venues].should include @closed_venue
      end

      it "should include ONLY closed venues when asked to with the closed parameter" do
        get :index, :all => '1', :closed => '1'
        assigns[:venues].should include @closed_venue
        assigns[:venues].should_not include @open_venue
      end
    end

    describe "when searching" do
      describe "for public wifi (and no keyword)" do
        before do
          get :index, :query => '', :wifi => '1'
        end

        it "should only include results with public wifi" do
          assigns[:venues].should include @wifi_venue
          assigns[:venues].should_not include @open_venue
        end
      end

      describe "when searching by keyword" do
        it "should find venues by title" do
          get :index, :query => 'Open Town'
          assigns[:venues].should include @open_venue
          assigns[:venues].should_not include @wifi_venue
        end
        it "should find venues by description" do
          get :index, :query => 'baz'
          assigns[:venues].should include @open_venue
          assigns[:venues].should_not include @wifi_venue
        end

        describe "and requiring public wifi" do
          it "should not find venues without public wifi" do
            get :index, :query => 'baz', :wifi => '1'
            assigns[:venues].should_not include @open_venue
            assigns[:venues].should_not include @wifi_venue
          end
        end
      end

      describe "when searching by title (for the ajax selector)" do
        it "should find venues by title" do
          get :index, :term => 'Open Town'
          assigns[:venues].should include @open_venue
          assigns[:venues].should_not include @wifi_venue
        end
        it "should NOT find venues by description" do
          get :index, :term => 'baz'
          assigns[:venues].should_not include @open_venue
        end
        it "should NOT find closed venues" do
          get :index, :term => 'closed'
          assigns[:venues].should_not include @closed_venue
        end
      end
    end

    it "should be able to return events matching specific tag" do
      Venue.should_receive(:tagged_with).with("foo").and_return([])
      get :index, :tag => "foo"
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
    describe "in JSON format" do
      describe "with events" do
        before do
          @venue = Factory.build(:venue, :id => 123)
          Venue.stub!(:find).and_return(@venue)
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
          @venue = Factory(:venue)
          @future_event = Factory(:event, :venue => @venue)
          @past_event = Factory(:event, :venue => @venue,
            :start_time => Time.now - 1.week + 1.hour,
            :end_time => Time.now - 1.week + 2.hours)

          get :show, :id => @venue.to_param, :format => "html"
          response.should be_success
        end

        it "should have a venue" do
          response.should have_selector(".location .fn", :content => @venue.title)
        end

        it "should have a future event" do
          response.should have_selector("#events #future_events .summary", :content => @future_event.title)
        end

        it "should have a past event" do
          response.should have_selector("#events #past_events .summary", :content => @past_event.title)
        end
      end
    end

  end

  describe "DELETE" do
    describe "when deleting a venue without events" do
      before do
        @venue = Factory(:venue)
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
        @event = Factory(:event_with_venue)
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
