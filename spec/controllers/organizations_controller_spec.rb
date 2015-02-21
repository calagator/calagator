require 'spec_helper'
require './spec/controllers/squash_many_duplicates_examples'

describe OrganizationsController, :type => :controller do
  render_views

  it "should redirect duplicate organizations to their master" do
    organization_master = FactoryGirl.create(:organization)
    organization_duplicate = FactoryGirl.create(:organization)

    # No redirect when they're unique
    get 'show', :id => organization_duplicate.id
    expect(response).not_to be_redirect
    expect(assigns(:organization).id).to eq organization_duplicate.id

    # Mark as duplicate
    organization_duplicate.duplicate_of = organization_master
    organization_duplicate.save!

    # Now check that redirection happens
    get 'show', :id => organization_duplicate.id
    expect(response).to be_redirect
    expect(response).to redirect_to(organization_url(organization_master.id))
  end

  it "should display an error message if given invalid arguments" do
    get 'duplicates', :type => 'omgwtfbbq'

    expect(response).to be_success
    expect(response.body).to have_selector('.failure', text: 'omgwtfbbq')
  end

  context do
    include_examples "#squash_many_duplicates", :organization
  end

  describe "when creating organizations" do
    it "should redirect to the newly created organization" do
      post :create, organization: FactoryGirl.attributes_for(:organization)
      expect(response).to redirect_to(assigns(:organization))
    end

    it "should stop evil robots" do
      post :create, :trap_field => "I AM AN EVIL ROBOT, I EAT OLD PEOPLE'S MEDICINE FOR FOOD!"
      expect(response).to render_template :new
    end
  end

  describe "when updating organizations" do
    before do
      @organization = FactoryGirl.create(:organization)
    end

    it "should redirect to the updated organization" do
      put :update, id: @organization.id, organization: FactoryGirl.attributes_for(:organization)
      expect(response).to redirect_to(@organization)
    end

    it "should redirect to any associated event" do
      @event = FactoryGirl.create(:event, organization: @organization)
      put :update, id: @organization.id, from_event: @event.id, organization: FactoryGirl.attributes_for(:organization)
      expect(response).to redirect_to(@event)
    end

    it "should stop evil robots" do
      put :update, id: @organization.id, trap_field: "I AM AN EVIL ROBOT, I EAT OLD PEOPLE'S MEDICINE FOR FOOD!"
      expect(response).to render_template :edit
    end
  end

  describe "when rendering the new organization page" do
    it "passes the template a new organization" do
      get :new
      expect(assigns[:organization]).to be_a Organization
      expect(assigns[:organization]).to be_new_record
    end
  end

  describe "when rendering the edit organization page" do
    it "passes the template the specified organization" do
      @organization = FactoryGirl.create(:organization)
      get :edit, id: @organization.id
      expect(assigns[:organization]).to eq(@organization)
    end
  end

  describe "when rendering the organizations index" do
    before do
      @organizations = [FactoryGirl.create(:organization), FactoryGirl.create(:organization)]
    end

    it "should assign the search object to @search" do
      get :index
      expect(assigns[:search]).to be_a Organization::Search
    end

    it "should assign search results to @organizations" do
      get :index
      expect(assigns[:organizations]).to eq(@organizations)
    end

    describe "in JSON format" do
      it "should produce JSON" do
        get :index, :format => "json"

        struct = ActiveSupport::JSON.decode(response.body)
        expect(struct).to be_a_kind_of Array
      end

      it "should accept a JSONP callback" do
        get :index, :format => "json", :callback => "some_function"

        expect(response.body.split("\n").join).to match /^\s*some_function\(.*\);?\s*$/
      end
    end

  end

  describe "when showing organizations" do
    it "redirects to all organizations if organization doesn't exist" do
      get :show, id: "garbage"
      expect(response).to redirect_to("/organizations")
    end

    describe "in JSON format" do
      describe "with events" do
        before do
          @organization = FactoryGirl.build(:organization, :id => 123)
          allow(Organization).to receive(:find).and_return(@organization)
        end

        it "should produce JSON" do
          get :show, :id => @organization.to_param, :format => "json"

          struct = ActiveSupport::JSON.decode(response.body)
          expect(struct).to be_a_kind_of Hash
          %w[id title description].each do |field|
            expect(struct[field]).to eq @organization.send(field)
          end
        end

        it "should accept a JSONP callback" do
          get :show, :id => @organization.to_param, :format => "json", :callback => "some_function"

          expect(response.body.split("\n").join).to match /^\s*some_function\(.*\);?\s*$/
        end
      end
    end

    describe "in HTML format" do
      describe "organization with future and past events" do
        before do
          @organization = FactoryGirl.create(:organization)
          @future_event = FactoryGirl.create(:event, :organization => @organization)
          @past_event = FactoryGirl.create(:event, :organization => @organization,
            :start_time => Time.now - 1.week + 1.hour,
            :end_time => Time.now - 1.week + 2.hours)

          get :show, :id => @organization.to_param, :format => "html"
          expect(response).to be_success
        end

        it "should have a organization" do
          expect(response.body).to have_selector(".location .fn", text: @organization.title)
        end

        it "should have a future event" do
          expect(response.body).to have_selector("#events #future_events .summary", text: @future_event.title)
        end

        it "should have a past event" do
          expect(response.body).to have_selector("#events #past_events .summary", text: @past_event.title)
        end
      end
    end

    describe "as an iCalendar" do
      before do
        @organization = FactoryGirl.create(:organization)
        @future_event = FactoryGirl.create(:event, :organization => @organization, :start_time => today + 1.hour)
        @past_event = FactoryGirl.create(:event, :organization => @organization, :start_time => today - 1.hour)

        get :show, :id => @organization.to_param, :format => "ics"
      end

      it "should have a calendar" do
        expect(response.body).to match /BEGIN:VCALENDAR/
      end

      it "should have events" do
        expect(response.body).to match /BEGIN:VEVENT/
      end

      it "should render all future events" do
        expect(response.body).to match /SUMMARY:#{@future_event.title}/
      end

      it "should render all past events" do
        expect(response.body).to match /SUMMARY:#{@past_event.title}/
      end
    end

  end

  describe "DELETE" do
    describe "when deleting a organization without events" do
      before do
        @organization = FactoryGirl.create(:organization)
      end

      shared_examples_for "destroying a Organization record without events" do
        it "should destroy the Organization record" do
          expect { Organization.find(@organization.id) }.to raise_error ActiveRecord::RecordNotFound
        end
      end

      describe "and rendering HTML" do
        before do
          delete :destroy, :id => @organization.id
        end

        it_should_behave_like "destroying a Organization record without events"

        it "should display a success message" do
          expect(flash[:success]).to be_present
        end

        it "should redirect to the organizations listing" do
          expect(response).to redirect_to(organizations_path)
        end
      end

      describe "and rendering XML" do
        render_views

        before do
          delete :destroy, :id => @organization.id, :format => "xml"
        end

        it_should_behave_like "destroying a Organization record without events"

        it "should return a success status" do
          expect(response).to be_success
        end
      end
    end

    describe "when deleting a organization with events" do
      before do
        @event = FactoryGirl.create(:event, :with_organization)
        @organization = @event.organization
      end

      shared_examples_for "destroying a Organization record with events" do
        it "should not destroy the Organization record" do
          expect(Organization.find(@organization.id)).to be_present
        end
      end

      describe "and rendering HTML" do
        before do
          delete :destroy, :id => @organization.id
        end

        it_should_behave_like "destroying a Organization record with events"

        it "should display a failure message" do
          expect(flash[:failure]).to be_present
        end

        it "should redirect to the organization page" do
          expect(response).to redirect_to(organization_path(@organization))
        end
      end

      describe "and rendering XML" do
        before do
          delete :destroy, :id => @organization.id, :format => "xml"
        end

        it_should_behave_like "destroying a Organization record with events"

        it "should return unprocessable entity status" do
          expect(response.code.to_i).to eq 422
        end

        it "should describing the problem" do
          expect(response.body).to match /cannot/i
        end
      end
    end
  end
end
