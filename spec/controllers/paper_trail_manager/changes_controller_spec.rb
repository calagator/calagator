# frozen_string_literal: true

require "spec_helper"

describe PaperTrailManager::ChangesController, type: :controller do
  routes { Calagator::Engine.routes }

  describe "#index" do
    render_views

    context "without changes" do
      it "shows no changes message" do
        get :index
        expect(response.body).to include("No changes found")
      end
    end

    context "with changes" do
      let!(:event1) { create(:event, title: "First Event") }
      let!(:event2) { create(:event, title: "Second Event") }
      let!(:venue1) { create(:venue, title: "First Venue") }

      before do
        event1.update!(title: "Updated First Event")
        event2.destroy
      end

      it "lists all changes" do
        get :index
        expect(response).to be_successful
        expect(response.body).to have_selector(".change_row", count: 5)
      end

      it "shows changes for all item types" do
        get :index
        expect(response.body).to have_selector(".change_item", text: /Event/)
        expect(response.body).to have_selector(".change_item", text: /Venue/)
      end

      it "orders changes with newest and highest id first" do
        get :index
        ids = response.body.scan(/Change #(\d+)/).flatten.map(&:to_i)
        expect(ids.length).to eq 5
        expect(ids.first).to be > ids.last
      end

      it "filters by item type" do
        get :index, params: {type: "Calagator::Event"}
        expect(response.body).to have_selector(".change_item", text: /Event/)
        expect(response.body).not_to have_selector(".change_item", text: /Venue/)
      end

      it "filters by item type and id" do
        get :index, params: {type: "Calagator::Event", id: event1.id}
        ids = response.body.scan(/Change #(\d+)/).flatten.map(&:to_i)
        version_ids = event1.versions.pluck(:id)
        expect(ids).to all(be_in(version_ids))
      end

      it "responds with atom feed" do
        get :index, format: :atom
        expect(response).to be_successful
        expect(response.content_type).to match(/atom/)
      end

      it "responds with json" do
        get :index, format: :json
        expect(response).to be_successful
        expect(response.content_type).to match(/json/)
      end
    end

    context "when index is not allowed" do
      before do
        PaperTrailManager.allow_index_block = proc { false }
      end

      after do
        PaperTrailManager.allow_index_block = proc { true }
      end

      it "redirects with an error message" do
        get :index
        expect(response).to redirect_to("/")
        expect(flash[:error]).to eq("You do not have permission to list changes.")
      end
    end
  end

  describe "#show" do
    render_views

    context "with a valid version" do
      let!(:event) { create(:event, title: "Test Event") }

      before do
        event.update!(title: "Updated Event")
      end

      it "displays the change" do
        version = event.versions.where(event: "create").first
        get :show, params: {id: version.id}
        expect(response).to be_successful
        expect(response.body).to include("Change ##{version.id}")
      end

      it "shows the event type" do
        version = event.versions.where(event: "update").first
        get :show, params: {id: version.id}
        expect(response.body).to include("change_event_update")
      end

      it "shows the associated record" do
        version = event.versions.where(event: "create").first
        get :show, params: {id: version.id}
        expect(response.body).to include("change_item")
        expect(response.body).to match(/Event/)
      end

      it "responds with json" do
        version = event.versions.where(event: "create").first
        get :show, params: {id: version.id}, format: :json
        expect(response).to be_successful
        expect(response.content_type).to match(/json/)
      end
    end

    context "with an invalid version id" do
      it "redirects with an error message" do
        get :show, params: {id: 999999}
        expect(response).to redirect_to(changes_path)
        expect(flash[:error]).to eq("No such version.")
      end
    end

    context "when show is not allowed" do
      let!(:event) { create(:event, title: "Test Event") }

      before do
        PaperTrailManager.allow_show_block = proc { |_controller, _version| false }
      end

      after do
        PaperTrailManager.allow_show_block = proc { true }
      end

      it "redirects with an error message" do
        version = event.versions.last
        get :show, params: {id: version.id}
        expect(response).to redirect_to(changes_path)
        expect(flash[:error]).to eq("You do not have permission to show that change.")
      end
    end
  end

  describe "#update (rollback)" do
    context "when rolling back a create" do
      let!(:event) { create(:event, title: "New Event") }

      it "destroys the newly-created record" do
        version = event.versions.where(event: "create").first
        expect(Calagator::Event.exists?(event.id)).to be true

        put :update, params: {id: version.id}

        expect(Calagator::Event.exists?(event.id)).to be false
        expect(response).to redirect_to(changes_path)
        expect(flash[:notice]).to match(/rolled back newly-created record/i)
      end
    end

    context "when rolling back an update" do
      let!(:event) { create(:event, title: "Original Title") }

      before do
        event.update!(title: "Changed Title")
      end

      it "reverts to the previous state" do
        version = event.versions.where(event: "update").last

        put :update, params: {id: version.id}

        event.reload
        expect(event.title).to eq("Original Title")
        expect(flash[:notice]).to match(/rolled back changes/i)
      end
    end

    context "when rolling back a destroy" do
      let!(:event) { create(:event, title: "Doomed Event") }
      let!(:event_id) { event.id }

      before do
        event.destroy
      end

      it "restores the deleted record" do
        expect(Calagator::Event.exists?(event_id)).to be false

        version = PaperTrail::Version.where(item_id: event_id, item_type: "Calagator::Event", event: "destroy").last

        put :update, params: {id: version.id}

        restored = Calagator::Event.find(event_id)
        expect(restored.title).to eq("Doomed Event")
      end
    end

    context "with an invalid version id" do
      it "redirects with an error message" do
        put :update, params: {id: 999999}
        expect(response).to redirect_to(changes_path)
        expect(flash[:error]).to eq("No such version.")
      end
    end

    context "when revert is not allowed" do
      let!(:event) { create(:event, title: "Test Event") }

      before do
        PaperTrailManager.allow_revert_block = proc { |_controller, _version| false }
      end

      after do
        PaperTrailManager.allow_revert_block = proc { true }
      end

      it "redirects with an error message" do
        version = event.versions.last
        put :update, params: {id: version.id}
        expect(response).to redirect_to(changes_path)
        expect(flash[:error]).to eq("You do not have permission to revert this change.")
      end
    end
  end
end
