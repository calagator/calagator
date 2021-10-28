# frozen_string_literal: true

require 'spec_helper'
require './spec/controllers/squash_many_duplicates_examples'

module Calagator
  describe EventsController, type: :controller do
    routes { Calagator::Engine.routes }

    describe '#index' do
      render_views

      describe 'as HTML' do
        it 'produces HTML' do
          get :index, format: 'html'

          expect(response.body).to have_selector 'table.event_table'
        end
      end

      describe 'as XML' do
        describe 'without events' do
          before do
            get :index, format: 'xml'

            @struct = Hash.from_xml(response.body)['events']
          end

          it 'does not have entries' do
            expect(@struct).to be_blank
          end
        end

        describe 'with events' do
          before do
            create(:event, :with_venue)
            create(:event, :with_venue)

            get :index, format: 'xml'

            @struct = Hash.from_xml(response.body)['events']
          end

          it 'returns an array of two items' do
            expect(@struct).to be_a_kind_of Array
            expect(@struct.count).to eq(2)
          end

          it 'has entries' do
            expect(@struct).to be_present
          end

          it 'includes venue details' do
            event = @struct.first
            venue = event['venue']
            venue_title = venue['title'] # Why XML? Why?
            expect(venue_title).to be_a_kind_of String
            expect(venue_title).to be_present
          end
        end
      end

      describe 'as JSON' do
        describe 'without events' do
          before do
            get :index, format: 'json'

            @struct = ActiveSupport::JSON.decode(response.body)
          end

          it 'returns an array' do
            expect(@struct).to be_a_kind_of Array
          end

          it 'does not have entries' do
            expect(@struct).to be_empty
          end
        end

        describe 'with events' do
          before do
            @event = create(:event, :with_venue)
            @venue = @event.venue

            get :index, format: 'json'

            @struct = ActiveSupport::JSON.decode(response.body)
          end

          it 'returns an array' do
            expect(@struct).to be_a_kind_of Array
          end

          it 'returns an event' do
            event = @struct.first
            expect(event['id']).to eq @event.id
            expect(event['title']).to eq @event.title
          end

          it "returns an event's venue" do
            event = @struct.first
            venue = event['venue']

            expect(venue['id']).to eq @venue.id
            expect(venue['title']).to eq @venue.title
          end
        end
      end

      describe 'as ATOM' do
        describe 'without events' do
          before do
            get :index, format: 'atom'
            @struct = Hash.from_xml(response.body)
          end

          it 'is a feed' do
            expect(@struct['feed']['xmlns']).to be_present
          end

          it 'does not have events' do
            expect(@struct['feed']['entry']).to be_blank
          end
        end

        describe 'with events' do
          before do
            create(:event, :with_venue)
            create(:event, :with_venue)

            get :index, format: 'atom'

            @struct = Hash.from_xml(response.body)
          end

          let(:entries) { @struct['feed']['entry'] }

          it 'is a feed' do
            expect(@struct['feed']['xmlns']).to be_present
          end

          it 'has entries' do
            expect(entries).to be_present
          end

          it 'has an event' do
            entry = entries.first
            record = Event.find(entry['id'][/(\d+)$/, 1])

            expect(Nokogiri.parse(entry['content']).search('.description p').inner_html).to eq record.description
            expect(entry['end_time']).to eq record.end_time.xmlschema
            expect(entry['start_time']).to eq record.start_time.xmlschema
            expect(entry['summary']).to be_present
            expect(entry['title']).to eq record.title
            expect(entry['updated']).to eq record.updated_at.xmlschema
            expect(entry['url']).to eq event_url(record)
          end
        end
      end

      describe 'as iCalendar' do
        describe 'without events' do
          before do
            get :index, format: 'ics'
          end

          it 'has a calendar' do
            expect(response.body).to match /BEGIN:VCALENDAR/
          end

          it 'does not have events' do
            expect(response.body).not_to match /BEGIN:VEVENT/
          end
        end

        describe 'with events' do
          before do
            @current_event = create(:event, start_time: today + 1.hour)
            @past_event = create(:event, start_time: today - 1.hour)

            get :index, format: 'ics'
          end

          it 'has a calendar' do
            expect(response.body).to match /BEGIN:VCALENDAR/
          end

          it 'has events' do
            expect(response.body).to match /BEGIN:VEVENT/
          end

          it 'renders all future events' do
            expect(response.body).to match /SUMMARY:#{@current_event.title}/
          end

          it 'does not render past events' do
            expect(response.body).not_to match(/SUMMARY:#{@past_event.title}/)
          end
        end
      end

      describe 'and filtering by date range' do
        let!(:within) do
          [
            Event.create!(
              title: 'matching1',
              start_time: Time.zone.parse('2010-01-16 00:00'),
              end_time: Time.zone.parse('2010-01-16 01:00')
            )
          ]
        end

        let!(:before) do
          [
            Event.create!(
              title: 'nonmatchingbefore',
              start_time: Time.zone.parse('2010-01-15 23:00'),
              end_time: Time.zone.parse('2010-01-15 23:59')
            )
          ]
        end

        let!(:after) do
          [
            Event.create!(
              title: 'nonmatchingafter',
              start_time: Time.zone.parse('2010-01-17 00:01'),
              end_time: Time.zone.parse('2010-01-17 01:00')
            )
          ]
        end

        it 'returns matching events' do
          get :index, params: { date: { start: '2010-01-16', end: '2010-01-16' } }
          expect(assigns[:events]).to eq within
        end
      end

      describe 'and filtering by time range' do
        around do |example|
          Timecop.freeze('2010-01-01') do
            example.run
          end
        end

        let!(:within) do
          [
            Event.create!(
              title: 'within',
              start_time: Time.zone.parse('2010-01-16 10:00'),
              end_time: Time.zone.parse('2010-01-16 11:00')
            )
          ]
        end

        let!(:before) do
          [
            Event.create!(
              title: 'before',
              start_time: Time.zone.parse('2010-01-16 05:00'),
              end_time: Time.zone.parse('2010-01-16 06:00')
            )
          ]
        end

        let!(:after) do
          [
            Event.create!(
              title: 'after',
              start_time: Time.zone.parse('2010-01-16 15:00'),
              end_time: Time.zone.parse('2010-01-16 16:00')
            )
          ]
        end

        it 'returns matching events before an end time' do
          get :index, params: { time: { start: '', end: '09:00 AM' } }
          expect(assigns[:events]).to eq before
        end

        it 'returns matching events within a time range' do
          get :index, params: { time: { start: '09:00 AM', end: '01:00 PM' } }
          expect(assigns[:events]).to eq within
        end

        it 'returns matching events after a start time' do
          get :index, params: { time: { start: '01:00 PM', end: '' } }
          expect(assigns[:events]).to eq after
        end
      end
    end

    describe '#show' do
      it 'shows an event' do
        event = Event.new(start_time: now)
        expect(Event).to receive(:find).and_return(event)

        get 'show', params: { id: 1234 }
        expect(response).to be_successful
      end

      it 'redirects from a duplicate event to its primary' do
        primary = create(:event, id: 4321)
        event = Event.new(start_time: now, duplicate_of: primary)
        expect(Event).to receive(:find).and_return(event)

        get 'show', params: { id: 1234 }
        expect(response).to redirect_to(event_path(primary))
      end

      it 'shows an error when asked to display a non-existent event' do
        expect(Event).to receive(:find).and_raise(ActiveRecord::RecordNotFound)

        get 'show', params: { id: 1234 }
        expect(response).to redirect_to(events_path)
        expect(flash[:failure]).not_to be_blank
      end
    end

    describe 'when creating and updating events' do
      before do
        @params = {
          'end_date' => '2008-06-04',
          'start_date' => '2008-06-03',
          'event' => {
            'title' => 'MyVenue',
            'url' => 'http://my.venue',
            'description' => 'Wheeeee'
          },
          'end_time' => '',
          'start_time' => ''
        }.with_indifferent_access
        @venue = build(:venue)
        @event = build(:event, venue: @venue)
      end

      describe '#new' do
        it 'displays form for creating new event' do
          get 'new'
          expect(response).to be_successful
          expect(response).to render_template :new
        end
      end

      describe '#create' do
        render_views

        it 'creates a new event without a venue' do
          @params[:event][:venue_id] = nil
          post :create, params: @params
          @event = Event.find_by(title: @params[:event][:title])
          expect(response).to redirect_to(@event)
        end

        it 'associates a venue based on a given venue id' do
          @venue.save!
          @params[:event][:venue_id] = @venue.id.to_s
          post :create, params: @params
          @event = Event.find_by(title: @params[:event][:title])
          expect(@event.venue).to eq(@venue)
          expect(response).to redirect_to(@event)
        end

        it 'associates a venue based on a given venue name' do
          @venue.save!
          @params[:venue_name] = @venue.title
          post :create, params: @params
          @event = Event.find_by(title: @params[:event][:title])
          expect(@event.venue).to eq(@venue)
          expect(response).to redirect_to(@event)
        end

        it 'associates a venue by id when both an id and a name are provided' do
          @venue.save!
          @venue2 = create(:venue)
          @params[:event][:venue_id] = @venue.id.to_s
          @params[:venue_name] = @venue2.title
          post :create, params: @params
          @event = Event.find_by(title: @params[:event][:title])
          expect(@event.venue).to eq(@venue)
          expect(response).to redirect_to(@event)
        end

        it 'creates a new event and new venue, and redirect to venue edit form' do
          @params[:venue_name] = 'New Venue'
          post :create, params: @params
          @event = Event.find_by(title: @params[:event][:title])
          @venue = Venue.find_by(title: 'New Venue')
          expect(@event.venue).to eq(@venue)
          expect(response).to redirect_to(edit_venue_url(@venue, from_event: @event.id))
        end

        it 'catches errors and redisplay the new event form' do
          post :create
          expect(response).to render_template :new
        end

        it 'stops evil robots' do
          post :create, params: { trap_field: "I AM AN EVIL ROBOT, I EAT OLD PEOPLE'S MEDICINE FOR FOOD!" }
          expect(response).to render_template :new
          expect(flash[:failure]).to match /evil robot/i
        end

        it 'does not allow too many links in the description' do
          @params[:event][:description] = <<-DESC
          http://example.com
          https://example.com
          http://example.net
          https://example.net
          DESC
          post :create, params: @params
          expect(response).to render_template :new
          expect(flash[:failure]).to match /too many links/i
        end

        it 'accepts HTTP-rich presentation descriptions without too many links' do
          @params[:event][:description] = <<-DESC
          I hereby offer to give a presentation at the August ruby meeting about the faraday
          gem (https://github.com/lostisland/faraday) and how compares to or compliments other
          HTTP client libraries such as httparty (https://github.com/jnunemaker/httparty).

          --

          I wouldn't mind seeing a PDX.pm talk about HTTP::Tiny vs Net::HTTP::Tiny vs Net::HTTP
          vs HTTP::Client vs HTTP::Client::Parallel
          DESC
          post :create, params: @params
          expect(flash[:failure]).to be_nil
        end

        it 'allows the user to preview the event' do
          @params[:preview] = 'Preview'
          post :create, params: @params
          expect(response).to render_template :new
          expect(response.body).to have_selector '#event_preview'
        end

        it 'creates an event for an existing venue' do
          venue = create(:venue)

          post :create, params: {
               start_time: now.strftime('%Y-%m-%d'),
               end_time: (now + 1.hour).strftime('%Y-%m-%d'),
               event: {
                 title: 'My Event',
                 tag_list: ',,foo,bar, baz,'
               },
               venue_name: venue.title            
          }

          expect(response).to be_redirect

          expect(flash[:success]).to be_present

          event = assigns[:event]
          expect(event.title).to eq 'My Event'
          expect(event.venue.title).to eq venue.title
          expect(event.venue.id).to eq venue.id
          expect(event.tag_list.to_a.sort).to eq %w[bar baz foo]
        end
      end

      describe '#update' do
        before do
          @event = create(:event, :with_venue, id: 42)
          @venue = @event.venue
          @params.merge!(id: 42)
        end

        it 'displays form for editing event' do
          get 'edit', params: { id: 42 }
          expect(response).to be_successful
          expect(response).to render_template :edit
        end

        it 'updates an event without a venue' do
          @event.venue = nil
          put 'update', params: @params
          expect(response).to redirect_to(@event)
        end

        it 'associates a venue based on a given venue id' do
          @venue = create(:venue)
          @params[:event][:venue_id] = @venue.id.to_s
          put 'update', params: @params
          expect(@event.reload.venue).to eq(@venue)
          expect(response).to redirect_to(@event)
        end

        it 'associates a venue based on a given venue name' do
          @venue = create(:venue)
          @params[:venue_name] = @venue.title
          put 'update', params: @params
          expect(@event.reload.venue).to eq(@venue)
          expect(response).to redirect_to(@event)
        end

        it 'associates a venue by id when both an id and a name are provided' do
          @venue = create(:venue)
          @venue2 = create(:venue)
          @params[:event][:venue_id] = @venue.id.to_s
          @params[:venue_name] = @venue2.title
          put 'update', params: @params
          expect(@event.reload.venue).to eq(@venue)
          expect(response).to redirect_to(@event)
        end

        it 'updates an event and create a new venue, and redirect to the venue edit form' do
          @params[:venue_name] = 'New Venue'
          put 'update', params: @params
          @venue = Venue.find_by(title: 'New Venue')
          expect(response).to redirect_to(edit_venue_url(@venue, from_event: @event.id))
        end

        it 'catches errors and redisplay the new event form' do
          @params[:event][:title] = nil
          put 'update', params: @params
          expect(response).to render_template :edit
        end

        it 'stops evil robots' do
          @params[:trap_field] = "I AM AN EVIL ROBOT, I EAT OLD PEOPLE'S MEDICINE FOR FOOD!"
          put 'update', params: @params
          expect(response).to render_template :edit
          expect(flash[:failure]).to match /evil robot/i
        end

        it 'does not allow too many links in the description' do
          @params[:event][:description] = <<-DESC
          http://example.com
          https://example.com
          http://example.net
          https://example.net
          DESC
          put 'update', params: @params
          expect(response).to render_template :edit
          expect(flash[:failure]).to match /too many links/i
        end

        it 'allows the user to preview the event' do
          put 'update', params: @params.merge(preview: 'Preview')
          expect(response).to render_template :edit
        end

        it 'does not allow a user to update a locked event' do
          @event.lock_editing!
          put 'update', params: @params
          expect(response).to be_redirect
          expect(flash[:failure]).to match /not permitted/i
        end
      end

      describe '#clone' do
        before do
          @event = create(:event)

          allow(Event).to receive(:find).and_return(@event)

          get 'clone', params: { id: 1 }
        end

        it 'builds an unsaved record' do
          record = assigns[:event]
          expect(record).to be_a_new_record
          expect(record.id).to be_nil
        end

        it 'builds a cloned record similar to the existing record' do
          record = assigns[:event]
          %w[title description venue_id venue_details].each do |field|
            expect(record.attributes[field]).to eq @event.attributes[field]
          end
        end

        it 'displays a new event form' do
          expect(response).to be_successful
          expect(response).to render_template :new
        end

        it 'has notice with cloning instructions' do
          expect(flash[:success]).to match /clone/i
        end
      end
    end

    context 'with admin auth for duplicates' do
      before do
        credentials = ActionController::HttpAuthentication::Basic.encode_credentials Calagator.admin_username, Calagator.admin_password
        request.env['HTTP_AUTHORIZATION'] = credentials
      end

      describe '#duplicates' do
        render_views

        it 'finds current duplicates and not past duplicates' do
          current_primary = create(:event, title: 'Current')
          current_duplicate = create(:event, title: current_primary.title)

          past_primary = create(:event, title: 'Past', start_time: now - 2.days)
          past_duplicate = create(:event, title: past_primary.title, start_time: now - 1.day)

          get 'duplicates', params: { type: 'title' }

          # Current duplicates
          assigns[:grouped].select { |keys, _values| keys.include?(current_primary.title) }.tap do |events|
            expect(events).not_to be_empty
            expect(events.first.last.size).to eq 2
          end

          # Past duplicates
          expect(assigns[:grouped].select { |keys, _values| keys.include?(past_primary.title) }).to be_empty
        end

        it 'redirects duplicate events to their primary' do
          event_primary = create(:event)
          event_duplicate = create(:event)

          get 'show', params: { id: event_duplicate.id }
          expect(response).not_to be_redirect
          expect(assigns(:event).id).to eq event_duplicate.id

          event_duplicate.duplicate_of = event_primary
          event_duplicate.save!

          get 'show', params: { id: event_duplicate.id }
          expect(response).to be_redirect
          expect(response).to redirect_to(event_url(event_primary.id))
        end

        it 'displays an error message if given invalid arguments' do
          get 'duplicates', params: { type: 'omgwtfbbq' }

          expect(response).to be_successful
          expect(response.body).to have_selector('.failure', text: 'omgwtfbbq')
        end
      end

      context do
        include_examples '#squash_many_duplicates', :event
      end
    end

    describe '#search' do
      describe 'when returning results' do
        render_views

        let!(:current_event) { create(:event, :with_venue, title: 'MyQuery') }
        let!(:current_event_2) { create(:event, :with_venue, description: 'WOW myquery!') }
        let!(:past_event) { create(:event, :with_venue, title: 'old myquery') }

        describe 'in HTML format' do
          before do
            get :search, params: { query: 'myquery' }, format: 'html'
          end

          it 'assigns search result' do
            expect(assigns[:search]).to be_a Event::Search
          end

          it 'assigns matching events' do
            expect(assigns[:events]).to match_array([current_event, current_event_2, past_event])
          end

          it 'renders matching events' do
            have_selector 'table.event_table' do
              have_selector '.vevent a.summary', href: event_url(results[:past])
              have_selector '.vevent a.summary', href: event_url(results[:current])
            end
          end

          describe 'sidebar' do
            it 'has iCalendar feed' do
              have_selector '.sidebar a', href: search_events_url(query: @query, format: 'ics', protocol: 'webcal')
            end

            it 'has Atom feed' do
              have_selector '.sidebar a', href: search_events_url(query: @query, format: 'atom')
            end

            it 'has Google subscription' do
              ics_url = search_events_url(query: @query, format: 'ics')
              google_url = "https://www.google.com/calendar/render?cid=#{ics_url}"
              have_selector '.sidebar a', href: google_url
            end
          end
        end

        describe 'in XML format' do
          it 'produces XML' do
            get :search, params: { query: 'myquery' }, format: 'xml'

            hash = Hash.from_xml(response.body)
            expect(hash['events']).to be_a_kind_of Array
          end

          it 'includes venue details' do
            get :search, params: { query: 'myquery' }, format: 'xml'

            hash = Hash.from_xml(response.body)
            event = hash['events'].first
            venue = event['venue']
            venue_title = venue['title']
            expect(venue_title).to be_a_kind_of String
            expect(venue_title.length).to be_present
          end
        end

        describe 'in JSON format' do
          it 'produces JSON' do
            get :search, params: { query: 'myquery' }, format: 'json'

            struct = ActiveSupport::JSON.decode(response.body)
            expect(struct).to be_a_kind_of Array
          end

          it 'includes venue details' do
            get :search, params: { query: 'myquery' }, format: 'json'

            struct = ActiveSupport::JSON.decode(response.body)
            event = struct.first
            expect(event['venue']['title']).to be_a_kind_of String
            expect(event['venue']['title'].length).to be_present
          end
        end

        describe 'in ATOM format' do
          it 'produces ATOM' do
            get :search, params: { query: 'myquery' }, format: 'atom'

            hash = Hash.from_xml(response.body)
            expect(hash['feed']['entry']).to be_a_kind_of Array
          end
        end

        describe 'in ICS format' do
          it 'produces ICS' do
            get :search, params: { query: 'myquery' }, format: 'ics'

            expect(response.body).to match /BEGIN:VEVENT/
          end

          it 'produces events matching the query' do
            get :search, params: { query: 'myquery' }, format: 'ics'
            expect(response.body).to match /SUMMARY:#{current_event_2.title}/
            expect(response.body).to match /SUMMARY:#{past_event.title}/
          end
        end

        describe 'failures' do
          it 'sets search failures in the flash message' do
            allow_any_instance_of(Event::Search).to receive_messages failure_message: 'OMG'
            get :search
            expect(flash[:failure]).to eq('OMG')
          end

          it 'redirects to home if hard failure' do
            allow_any_instance_of(Event::Search).to receive_messages hard_failure?: true
            get :search
            expect(response).to redirect_to(root_path)
          end
        end
      end
    end

    describe '#destroy' do
      it 'destroys events' do
        event = build(:event)
        expect(event).to receive(:destroy)
        expect(Event).to receive(:find).and_return(event)

        delete 'destroy', params: { id: 1234 }
        expect(response).to redirect_to(events_url)
      end

      it 'does not allow a user to destroy a locked event' do
        event = create(:event)
        event.lock_editing!

        delete 'destroy', params: { id: event.id }
        expect(response).to be_redirect
        expect(flash[:failure]).to match /not permitted/i
      end
    end
  end
end
