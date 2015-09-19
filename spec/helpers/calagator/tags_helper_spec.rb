require 'spec_helper'

module Calagator

describe TagsHelper, type: :helper do
  describe "#tag_links_for" do
    it "renders tag links for the supplied model" do
      event = FactoryGirl.create(:event, tag_list: %w(b a))
      expect(tag_links_for(event)).to match_dom_of \
        %(<a href="/events/tag/a" class="p-category">a</a>, ) +
        %(<a href="/events/tag/b" class="p-category">b</a>)
    end
  end

  describe "#display_tag_icons" do
    before do
      @event = FactoryGirl.create(:event, :tag_list => ['ruby', 'pizza'])
      @event2 = FactoryGirl.create(:event, :tag_list => ['no_image', 'also_no_image'])
      @untagged_event = Event.new
    end

    it "should render image tags inline and whitespace separated" do
      expect(helper.display_tag_icons(@event)).to match_dom_of \
        %(<a href="/events/tag/ruby"><img title="ruby" src="/assets/tag_icons/ruby.png" alt="Ruby" /></a> ) +
        %(<a href="/events/tag/pizza"><img title="pizza" src="/assets/tag_icons/pizza.png" alt="Pizza" /></a>)

    end

    it "should render nothing if no image tags" do
      expect(helper.display_tag_icons(@event2)).to eq " "
    end

    it "should render nothing if event has no tags" do
      expect(helper.display_tag_icons(@untagged_event)).to eq ""
    end
  end
end

end
