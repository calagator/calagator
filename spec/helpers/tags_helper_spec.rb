require 'spec_helper'

describe TagsHelper, type: :helper do
  describe "#tag_links_for" do
    it "renders tag links for the supplied model" do
      event = FactoryGirl.create(:event, tag_list: %w(b a))
      expect(tag_links_for(event)).to eq(
        %(<a href="/events/tag/a" class="p-category">a</a>, ) +
        %(<a href="/events/tag/b" class="p-category">b</a>)
      )
    end
  end

  describe "#icon_exists_for?" do
    it "should return true if there is a PNG file in tag_icons with the name of the argument" do
      expect(helper.icon_exists_for?("pizza")).to eq true
    end

    it "should return false if there is not a PNG file in tag_icons with the name of the argument" do
      expect(helper.icon_exists_for?("no_image")).to eq false
    end
  end

  shared_context "tag icons" do
    before do
      @event = FactoryGirl.create(:event, :tag_list => ['ruby', 'pizza'])
      @event2 = FactoryGirl.create(:event, :tag_list => ['no_image', 'also_no_image'])
      @untagged_event = Event.new
    end
  end

  describe "#get_tag_icon_links" do
    include_context "tag icons"

    it "should generate an array of image tags" do
      helper.get_tag_icon_links(@event).each do |item|
        expect(item).to include "<img "
      end
    end

    it "should generate an array of link tags" do
      helper.get_tag_icon_links(@event).each do |item|
        expect(item).to include "<a "
      end
    end

    it "should generate items for each tag that has a corresponding image" do
      expect(helper.get_tag_icon_links(@event)[0]).to include "Ruby"
      expect(helper.get_tag_icon_links(@event)[0]).to include "ruby.png"
      expect(helper.get_tag_icon_links(@event)[1]).to include "Pizza"
      expect(helper.get_tag_icon_links(@event)[1]).to include "pizza.png"
    end

    it "should return nil values for tags that do not correspond to images" do
      expect(helper.get_tag_icon_links(@event2)).to eq [nil, nil]
    end

    it "should return a blank array if event has no tags" do
      expect(helper.get_tag_icon_links(@untagged_event)).to eq []
    end
  end

  describe "#display_tag_icons" do
    include_context "tag icons"

    it "should render image tags inline and whitespace separated" do
      expect(helper.display_tag_icons(@event)).to include "Ruby"
      expect(helper.display_tag_icons(@event)).to include "ruby.png"
      expect(helper.display_tag_icons(@event)).to include "Pizza"
      expect(helper.display_tag_icons(@event)).to include "pizza.png"
    end

    it "should render nothing if no image tags" do
      expect(helper.display_tag_icons(@event2)).to eq " "
    end

    it "should render nothing if event has no tags" do
      expect(helper.display_tag_icons(@untagged_event)).to eq ""
    end
  end
end
