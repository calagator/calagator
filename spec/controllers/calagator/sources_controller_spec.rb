# frozen_string_literal: true

require 'spec_helper'
require 'open-uri'

module Calagator
  describe SourcesController, type: :controller do
    routes { Calagator::Engine.routes }

    describe 'using import logic' do
      before do
        @venue = mock_model(Venue,
                            :source => nil,
                            :source= => true,
                            :save! => true,
                            :duplicate_of_id => nil)

        @event = mock_model(Event,
                            :title => 'Super Event',
                            :source= => true,
                            :save! => true,
                            :venue => @venue,
                            :start_time => Time.now.in_time_zone + 1.week,
                            :end_time => nil,
                            :old? => false,
                            :duplicate_of_id => nil)

        @source = Source.new(url: 'http://my.url/')
        allow(@source).to receive(:save!).and_return(true)
        allow(@source).to receive(:to_events).and_return([@event])

        allow(Source).to receive(:new).and_return(@source)
        allow(Source).to receive(:find_or_create_by).with(hash_including(url: 'http://my.url/')).and_return(@source)
      end

      it 'provides a way to create new sources' do
        get :new
        expect(assigns(:source)).to be_a_kind_of Source
        expect(assigns(:source)).to be_a_new_record
      end

      describe 'with render views' do
        render_views

        it 'saves the source object when creating events' do
          expect(@source).to receive(:save!)
          post :import, params: { source: { url: @source.url } }
          expect(flash[:success]).to match(/Imported/i)
        end

        it 'limits the number of created events to list in the flash' do
          excess = 5
          events = (1..(5 + excess))\
                   .each_with_object([]) { |_i, result| result << @event }
          allow(@source).to receive(:to_events).and_return(events)
          post :import, params: { source: { url: @source.url } }
          expect(flash[:success]).to match(/And #{excess} other events/si)
        end
      end

      it 'assigns newly-created events to the source' do
        post :import, params: { source: { url: @source.url } }
        expect(@event).to be_persisted
      end

      it 'assigns newly created venues to the source' do
          post :import, params: { source: { url: @source.url } }
        expect(@venue).to be_persisted
      end

      describe 'is given problematic sources' do
        before do
          @source = stub_model(Source)
          allow(Source).to receive(:find_or_create_by).with(hash_including(url: 'http://invalid.host')).and_return(@source)
        end

        def assert_import_raises(exception)
          expect(@source).to receive(:create_events!).and_raise(exception)
          post :import, params: { source: { url: 'http://invalid.host' } }
        end

        it 'fails when host responds with no events' do
          allow(@source).to receive(:create_events!).and_return([])
          post :import, params: { source: { url: 'http://invalid.host' } }
          expect(flash[:failure]).to match(/Unable to find any upcoming events to import from this source/)
        end

        it 'fails when host responds with a 404' do
          assert_import_raises(Source::Parser::NotFound)
          expect(flash[:failure]).to match(/No events found at remote site/)
        end

        it 'fails when host responds with an error' do
          assert_import_raises(OpenURI::HTTPError.new('omfg', 'bbq'))
          expect(flash[:failure]).to match(/Couldn't download events/)
        end

        it 'fails when host is not responding' do
          assert_import_raises(Errno::EHOSTUNREACH.new('omfg'))
          expect(flash[:failure]).to match(/Couldn't connect to remote site/)
        end

        it 'fails when host is not found' do
          assert_import_raises(SocketError.new('omfg'))
          expect(flash[:failure]).to match(/Couldn't find IP address for remote site/)
        end

        it 'fails when host requires authentication' do
          assert_import_raises(Source::Parser::HttpAuthenticationRequiredError.new('omfg'))
          expect(flash[:failure]).to match(/requires authentication/)
        end

        it 'fails when host throws something strange' do
          assert_import_raises(TypeError)
          expect(flash[:failure]).to match(/Unknown error: TypeError/)
        end
      end
    end

    describe 'handling GET /sources' do
      before do
        @source = mock_model(Source)
        allow(Source).to receive(:listing).and_return([@source])
      end

      def do_get
        get :index
      end

      it 'is successful' do
        do_get
        expect(response).to be_successful
      end

      it 'renders index template' do
        do_get
        expect(response).to render_template :index
      end

      it 'finds sources' do
        expect(Source).to receive(:listing)
        do_get
      end

      it 'assigns the found sources for the view' do
        do_get
        expect(assigns[:sources]).to eq [@source]
      end
    end

    describe 'handling GET /sources.xml' do
      before do
        @sources = double('Array of Sources', to_xml: 'XML')
        allow(Source).to receive(:listing).and_return(@sources)
      end

      def do_get
        @request.env['HTTP_ACCEPT'] = 'application/xml'
        get :index
      end

      it 'is successful' do
        do_get
        expect(response).to be_successful
      end

      it 'finds all sources' do
        expect(Source).to receive(:listing)
        do_get
      end

      it 'renders the found sources as xml' do
        do_get
        expect(response.content_type).to eq 'application/xml'
      end
    end

    describe 'show' do
      it 'redirects when asked for unknown source' do
        expect(Source).to receive(:find).and_raise(ActiveRecord::RecordNotFound.new)
        get :show, params: { id: '1' }

        expect(response).to be_redirect
      end
    end

    describe 'handling GET /sources/1' do
      before do
        @source = mock_model(Source)
        allow(Source).to receive(:find).and_return(@source)
      end

      def do_get
        get :show, params: { id: '1' }
      end

      it 'is successful' do
        do_get
        expect(response).to be_successful
      end

      it 'renders show template' do
        do_get
        expect(response).to render_template :show
      end

      it 'finds the source requested' do
        expect(Source).to receive(:find).with('1', include: %i[events venues])
        do_get
      end

      it 'assigns the found source for the view' do
        do_get
        expect(assigns[:source]).to eq @source
      end
    end

    describe 'handling GET /sources/1.xml' do
      before do
        @source = mock_model(Source, to_xml: 'XML')
        allow(Source).to receive(:find).and_return(@source)
      end

      def do_get
        @request.env['HTTP_ACCEPT'] = 'application/xml'
        get :show, params: { id: '1' }
      end

      it 'is successful' do
        do_get
        expect(response).to be_successful
      end

      it 'finds the source requested' do
        expect(Source).to receive(:find).with('1', include: %i[events venues])
        do_get
      end

      it 'renders the found source as xml' do
        expect(@source).to receive(:to_xml).and_return('XML')
        do_get
        expect(response.body).to eq 'XML'
      end
    end

    describe 'handling GET /sources/new' do
      before do
        @source = mock_model(Source)
        allow(Source).to receive(:new).and_return(@source)
      end

      def do_get
        get :new
      end

      it 'is successful' do
        do_get
        expect(response).to be_successful
      end

      it 'renders new template' do
        do_get
        expect(response).to render_template :new
      end

      it 'creates an new source' do
        expect(Source).to receive(:new)
        do_get
      end

      it 'does not save the new source' do
        expect(@source).not_to receive(:save)
        do_get
      end

      it 'assigns the new source for the view' do
        do_get
        expect(assigns[:source]).to eq @source
      end
    end

    describe 'handling GET /sources/1/edit' do
      before do
        @source = mock_model(Source)
        allow(Source).to receive(:find).and_return(@source)
      end

      def do_get
        get :edit, params: { id: '1' }
      end

      it 'is successful' do
        do_get
        expect(response).to be_successful
      end

      it 'renders edit template' do
        do_get
        expect(response).to render_template :edit
      end

      it 'finds the source requested' do
        expect(Source).to receive(:find)
        do_get
      end

      it 'assigns the found Source for the view' do
        do_get
        expect(assigns[:source]).to eq @source
      end
    end

    describe 'handling POST /sources' do
      before do
        @source = mock_model(Source, to_param: '1')
        allow(Source).to receive(:new).and_return(@source)
      end

      describe 'with successful save' do
        def do_post
          allow(@source).to receive(:update).and_return(true)
          post :create, params: { source: {} }
        end

        it 'creates a new source' do
          expect(Source).to receive(:new)
          do_post
        end

        it 'redirects to the new source' do
          do_post
          expect(response).to redirect_to(source_url('1'))
        end
      end

      describe 'with failed save' do
        def do_post
          allow(@source).to receive(:update).and_return(false)
          allow(@source).to receive_messages(new_record?: true)
          post :create, params: { source: {} }
        end

        it "re-renders 'new'" do
          do_post
          expect(response).to render_template :new
        end
      end
    end

    describe 'handling PUT /sources/1' do
      before do
        @source = mock_model(Source, to_param: '1')
        allow(Source).to receive(:find).and_return(@source)
      end

      describe 'with successful update' do
        def do_put
          allow(@source).to receive(:update).and_return(true)
          put :update, params: { id: '1' }
        end

        it 'finds the source requested' do
          expect(Source).to receive(:find).with('1')
          do_put
        end

        it 'updates the found source' do
          do_put
          expect(assigns(:source)).to eq @source
        end

        it 'assigns the found source for the view' do
          do_put
          expect(assigns(:source)).to eq @source
        end

        it 'redirects to the source' do
          do_put
          expect(response).to redirect_to(source_url('1'))
        end
      end

      describe 'with failed update' do
        def do_put
          allow(@source).to receive(:update).and_return(false)
          put :update, params: { id: '1' }
        end

        it "re-renders 'edit'" do
          do_put
          expect(response).to render_template :edit
        end
      end
    end

    describe 'handling DELETE /sources/1' do
      before do
        @source = mock_model(Source, destroy: true)
        allow(Source).to receive(:find).and_return(@source)
      end

      def do_delete
        delete :destroy, params: { id: '1' }
      end

      it 'finds the source requested' do
        expect(Source).to receive(:find).with('1')
        do_delete
      end

      it 'calls destroy on the found source' do
        expect(@source).to receive(:destroy)
        do_delete
      end

      it 'redirects to the sources list' do
        do_delete
        expect(response).to redirect_to(sources_url)
      end
    end
  end
end
