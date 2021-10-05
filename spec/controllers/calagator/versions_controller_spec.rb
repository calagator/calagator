# frozen_string_literal: true

require 'spec_helper'

module Calagator
  describe VersionsController, type: :controller do
    routes { Calagator::Engine.routes }

    describe 'without versions' do
      it 'raises RecordNotFound if not given an id' do
        expect do
          get :edit, params: { id: '' }
        end.to raise_error ActiveRecord::RecordNotFound
      end

      it 'raises RecordNotFound if given invalid id' do
        expect do
          get :edit, params: { id: '-1' }
        end.to raise_error ActiveRecord::RecordNotFound
      end

      it "raises RecordNotFound if given id that doesn't exist" do
        expect do
          get :edit, params: { id: '1234' }
        end.to raise_error ActiveRecord::RecordNotFound
      end
    end

    describe 'with versions' do
      before do
        @create_title = 'myevent'
        @update_title = 'myevent v2'
        @final_title = 'myevent v3'

        @event = create(:event, title: @create_title)

        @event.title = @update_title
        @event.save!

        @event.title = @final_title
        @event.save!

        @event.destroy
      end

      # Returns the versioned record's title for the event (e.g. :update).
      def title_for(event)
        version_id = @event.versions.where(event: event).pluck(:id).first

        get :edit, params: { id: version_id }

        assigns[:event].title
      end

      it "renders the initial content for a 'create'" do
        expect(title_for(:create)).to eq @create_title
      end

      it "renders the updated content for an 'update'" do
        expect(title_for(:update)).to eq @update_title
      end

      it "renders the final content for a 'destroy'" do
        expect(title_for(:destroy)).to eq @final_title
      end

      it 'renders html' do
        version_id = @event.versions.first.id
        get :edit, params: { id: version_id }
        expect(response).to be_success
        expect(response).to render_template 'events/edit'
      end

      it 'renders html via xhr' do
        version_id = @event.versions.first.id
        xhr :get, :edit, params: { id: version_id }
        expect(response).to be_success
        expect(response).to render_template 'events/_form'
      end
    end
  end
end
