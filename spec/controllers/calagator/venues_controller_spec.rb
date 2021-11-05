# frozen_string_literal: true

require 'spec_helper'
require './spec/controllers/squash_many_duplicates_examples'

module Calagator
  describe VenuesController, type: :controller do
    routes { Calagator::Engine.routes }

    render_views

    context 'concerning duplicates' do
      let!(:venue_primary) { create(:venue) }
      let!(:venue_duplicate) { create(:venue, duplicate_of: venue_primary) }

      it 'redirects duplicate venues to their primary' do
        get 'show', params: { id: venue_duplicate.id }
        expect(response).to redirect_to(venue_url(venue_primary.id))
      end

      it "doesn't redirect non-duplicates" do
        get 'show', params: { id: venue_primary.id }
        expect(response).not_to be_redirect
        expect(assigns(:venue).id).to eq venue_primary.id
      end
    end

    context 'with admin auth for duplicates' do
      before do
        credentials = ActionController::HttpAuthentication::Basic.encode_credentials Calagator.admin_username, Calagator.admin_password
        request.env['HTTP_AUTHORIZATION'] = credentials
      end

      it 'displays an error message if given invalid arguments' do
        get 'duplicates', params: { type: 'omgwtfbbq' }

        expect(response).to be_successful
        expect(response.body).to have_selector('.failure', text: 'omgwtfbbq')
      end

      context do
        include_examples '#squash_many_duplicates', :venue
      end
    end

    describe 'when creating venues' do
      it 'redirects to the newly created venue' do
        post :create, params: { venue: attributes_for(:venue) }
        expect(response).to redirect_to(assigns(:venue))
      end

      it 'stops evil robots' do
        post :create, params: { trap_field: "I AM AN EVIL ROBOT, I EAT OLD PEOPLE'S MEDICINE FOR FOOD!" }
        expect(response).to render_template :new
      end
    end

    describe 'when updating venues' do
      before do
        @venue = create(:venue)
      end

      it 'redirects to the updated venue' do
        put :update, params: { id: @venue.id, venue: attributes_for(:venue) }
        expect(response).to redirect_to(@venue)
      end

      it 'redirects to any associated event' do
        @event = create(:event, venue: @venue)
        put :update, params: { id: @venue.id, from_event: @event.id, venue: attributes_for(:venue) }
        expect(response).to redirect_to(@event)
      end

      it 'stops evil robots' do
        put :update, params: { id: @venue.id, trap_field: "I AM AN EVIL ROBOT, I EAT OLD PEOPLE'S MEDICINE FOR FOOD!" }
        expect(response).to render_template :edit
      end
    end

    describe 'when rendering the new venue page' do
      it 'passes the template a new venue' do
        get :new
        expect(assigns[:venue]).to be_a Venue
        expect(assigns[:venue]).to be_new_record
      end
    end

    describe 'when rendering the edit venue page' do
      it 'passes the template the specified venue' do
        @venue = create(:venue)
        get :edit, params: { id: @venue.id }
        expect(assigns[:venue]).to eq(@venue)
      end
    end

    describe 'when rendering the map page' do
      before do
        @open_venue = create(:venue)
        @closed_venue = create(:venue, closed: true)
        @duplicate_venue = create(:venue, duplicate_of: @open_venue)
      end

      it 'only shows open non-duplicate venues' do
        get :map
        expect(assigns[:venues]).to eq([@open_venue])
      end
    end

    describe 'when rendering the venues index' do
      before do
        @venues = [create(:venue), create(:venue)]
      end

      it 'assigns the search object to @search' do
        get :index
        expect(assigns[:search]).to be_a Venue::Search
      end

      it 'assigns search results to @venues' do
        get :index
        expect(assigns[:venues]).to eq(@venues)
      end

      describe 'in JSON format' do
        it 'produces JSON' do
          get :index, format: 'json'

          struct = ActiveSupport::JSON.decode(response.body)
          expect(struct).to be_a_kind_of Array
        end
      end
    end

    describe 'when showing venues' do
      it "redirects to all venues if venue doesn't exist" do
        get :show, params: { id: 'garbage' }
        expect(response).to redirect_to('/venues')
      end

      describe 'in JSON format' do
        describe 'with events' do
          before do
            @venue = build(:venue, id: 123)
            allow(Venue).to receive(:find).and_return(@venue)
          end

          it 'produces JSON' do
            get :show, params: { id: @venue.to_param }, format: 'json'

            struct = ActiveSupport::JSON.decode(response.body)
            expect(struct).to be_a_kind_of Hash
            %w[id title description address].each do |field|
              expect(struct[field]).to eq @venue.send(field)
            end
          end
        end
      end

      describe 'in HTML format' do
        describe 'venue with future and past events' do
          before do
            @venue = create(:venue)
            @future_event = create(:event, venue: @venue)
            @past_event = create(:event, venue: @venue,
                                                    start_time: Time.now.in_time_zone - 1.week + 1.hour,
                                                    end_time: Time.now.in_time_zone - 1.week + 2.hours)

            get :show, params: { id: @venue.to_param }, format: 'html'
            expect(response).to be_successful
          end

          it 'has a venue' do
            expect(response.body).to have_selector('.location .fn', text: @venue.title)
          end

          it 'has a future event' do
            expect(response.body).to have_selector('#events #future_events .summary', text: @future_event.title)
          end

          it 'has a past event' do
            expect(response.body).to have_selector('#events #past_events .summary', text: @past_event.title)
          end
        end
      end

      describe 'as an iCalendar' do
        before do
          @venue = create(:venue)
          @future_event = create(:event, venue: @venue, start_time: today + 1.hour)
          @past_event = create(:event, venue: @venue, start_time: today - 1.hour)

          get :show, params: { id: @venue.to_param }, format: 'ics'
        end

        it 'has a calendar' do
          expect(response.body).to match /BEGIN:VCALENDAR/
        end

        it 'has events' do
          expect(response.body).to match /BEGIN:VEVENT/
        end

        it 'renders all future events' do
          expect(response.body).to match /SUMMARY:#{@future_event.title}/
        end

        it 'renders all past events' do
          expect(response.body).to match /SUMMARY:#{@past_event.title}/
        end
      end
    end

    describe 'DELETE' do
      describe 'when deleting a venue without events' do
        before do
          @venue = create(:venue)
        end

        shared_examples_for 'destroying a Venue record without events' do
          it 'destroys the Venue record' do
            expect { Venue.find(@venue.id) }.to raise_error ActiveRecord::RecordNotFound
          end
        end

        describe 'and rendering HTML' do
          before do
            delete :destroy, params: { id: @venue.id }
          end

          it_behaves_like 'destroying a Venue record without events'

          it 'displays a success message' do
            expect(flash[:success]).to be_present
          end

          it 'redirects to the venues listing' do
            expect(response).to redirect_to(venues_path)
          end
        end

        describe 'and rendering XML' do
          render_views

          before do
            delete :destroy, params: { id: @venue.id }, format: 'xml'
          end

          it_behaves_like 'destroying a Venue record without events'

          it 'returns a success status' do
            expect(response).to be_successful
          end
        end
      end

      describe 'when deleting a venue with events' do
        before do
          @event = create(:event, :with_venue)
          @venue = @event.venue
        end

        shared_examples_for 'destroying a Venue record with events' do
          it 'does not destroy the Venue record' do
            expect(Venue.find(@venue.id)).to be_present
          end
        end

        describe 'and rendering HTML' do
          before do
            delete :destroy, params: { id: @venue.id }
          end

          it_behaves_like 'destroying a Venue record with events'

          it 'displays a failure message' do
            expect(flash[:failure]).to be_present
          end

          it 'redirects to the venue page' do
            expect(response).to redirect_to(venue_path(@venue))
          end
        end

        describe 'and rendering XML' do
          before do
            delete :destroy, params: { id: @venue.id }, format: 'xml'
          end

          it_behaves_like 'destroying a Venue record with events'

          it 'returns unprocessable entity status' do
            expect(response.code.to_i).to eq 422
          end

          it 'describings the problem' do
            expect(response.body).to match /cannot/i
          end
        end
      end
    end
  end
end
