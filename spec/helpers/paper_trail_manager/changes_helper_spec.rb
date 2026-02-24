# frozen_string_literal: true

require "spec_helper"

describe PaperTrailManager::ChangesHelper, type: :helper do
  before do
    # ChangesHelper expects these helper methods from the controller
    allow(helper).to receive(:change_item_url).and_return(nil)
  end

  describe "#text_or_nil" do
    it "returns the escaped text for a non-nil value" do
      expect(helper.text_or_nil("hello")).to eq("hello")
    end

    it "returns an em tag for nil" do
      expect(helper.text_or_nil(nil)).to eq("<em>nil</em>")
    end

    it "escapes HTML in the value" do
      expect(helper.text_or_nil("<script>")).to eq("&lt;script&gt;")
    end
  end

  describe "#changes_for" do
    # NOTE: The versions table does not have an object_changes column,
    # so changeset returns nil for create/update events. The destroy
    # path uses reify instead.

    context "with a create event" do
      let(:event) { create(:event, title: "New Event") }
      let(:version) { event.versions.where(event: "create").first }

      it "returns an empty hash when changeset is nil" do
        expect(helper.changes_for(version)).to eq({})
      end
    end

    context "with an update event" do
      let(:event) { create(:event, title: "Original") }

      before do
        event.update!(title: "Updated")
      end

      let(:version) { event.versions.where(event: "update").last }

      it "returns an empty hash when changeset is nil" do
        expect(helper.changes_for(version)).to eq({})
      end
    end

    context "with a create event that has a changeset" do
      let(:event) { create(:event, title: "New Event") }
      let(:version) { event.versions.where(event: "create").first }

      it "returns changes with previous and current values" do
        changeset = {"title" => [nil, "New Event"]}
        allow(version).to receive(:changeset).and_return(changeset)

        changes = helper.changes_for(version)
        expect(changes["title"]).to eq(previous: nil, current: "New Event")
      end
    end

    context "with an update event that has a changeset" do
      let(:event) { create(:event, title: "Original") }

      before do
        event.update!(title: "Updated")
      end

      let(:version) { event.versions.where(event: "update").last }

      it "returns changes with previous and current values" do
        changeset = {"title" => ["Original", "Updated"]}
        allow(version).to receive(:changeset).and_return(changeset)

        changes = helper.changes_for(version)
        expect(changes["title"]).to eq(previous: "Original", current: "Updated")
      end
    end

    context "with a destroy event" do
      let(:event) { create(:event, title: "Gone Event") }
      let!(:event_id) { event.id }

      before do
        event.destroy
      end

      let(:version) { PaperTrail::Version.where(item_id: event_id, item_type: "Calagator::Event", event: "destroy").last }

      it "returns attributes with current values as nil" do
        changes = helper.changes_for(version)
        expect(changes).to be_a(Hash)
        expect(changes["title"][:previous]).to eq("Gone Event")
        expect(changes["title"][:current]).to be_nil
      end
    end

    context "with an unknown event type" do
      let(:event) { create(:event, title: "Test") }
      let(:version) { event.versions.last }

      it "raises ArgumentError" do
        allow(version).to receive(:event).and_return("unknown")
        expect { helper.changes_for(version) }.to raise_error(ArgumentError, /Unknown event/)
      end
    end
  end

  describe "#change_title_for" do
    let(:event) { create(:event, title: "My Event") }
    let(:version) { event.versions.last }

    it "returns the item title using the configured method" do
      expect(helper.change_title_for(version)).to eq("My Event")
    end

    context "when item_name_method is not configured" do
      before do
        allow(PaperTrailManager).to receive(:item_name_method).and_return(nil)
      end

      it "returns type and id as a string" do
        expect(helper.change_title_for(version)).to include("Calagator::Event")
        expect(helper.change_title_for(version)).to include(event.id.to_s)
      end
    end
  end

  describe "#change_item_types" do
    it "returns model names that include PaperTrail" do
      # Ensure models are loaded so subclasses are registered
      Calagator::Event.count
      Calagator::Venue.count

      types = helper.change_item_types
      expect(types).to include("Calagator::Event")
      expect(types).to include("Calagator::Venue")
    end
  end

  describe "#change_item_link" do
    let(:event) { create(:event, title: "Linked Event") }
    let(:version) { event.versions.last }

    context "when the item URL exists" do
      before do
        allow(helper).to receive(:change_item_url).with(version).and_return("/events/#{event.id}")
      end

      it "returns a link to the item" do
        result = helper.change_item_link(version)
        expect(result).to have_selector("a.change_item", text: "Linked Event")
      end
    end

    context "when the item URL is nil" do
      before do
        allow(helper).to receive(:change_item_url).with(version).and_return(nil)
      end

      it "returns a span with the item title" do
        result = helper.change_item_link(version)
        expect(result).to have_selector("span.change_item", text: "Linked Event")
      end
    end
  end

  describe "#version_reify" do
    let(:event) { create(:event, title: "Reify Me") }

    context "with a valid version" do
      before do
        event.update!(title: "Updated")
      end

      let(:version) { event.versions.where(event: "update").last }

      it "returns the reified record" do
        record = helper.version_reify(version)
        expect(record).to be_a(Calagator::Event)
        expect(record.title).to eq("Reify Me")
      end
    end

    context "when reify raises an ArgumentError" do
      let(:version) { event.versions.last }

      it "returns nil" do
        allow(version).to receive(:reify).and_raise(ArgumentError)
        expect(helper.version_reify(version)).to be_nil
      end
    end
  end
end
