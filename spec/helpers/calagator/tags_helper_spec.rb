# frozen_string_literal: true

require 'spec_helper'

module Calagator
  describe TagsHelper, type: :helper do
    describe '#tag_links_for' do
      it 'renders tag links for the supplied model' do
        event = create(:event, tag_list: %w[b a])
        expect(tag_links_for(event)).to match_dom_of \
          %(<a href="/events/tag/a" class="p-category">a</a>, ) +
          %(<a href="/events/tag/b" class="p-category">b</a>)
      end
    end

    describe '#display_tag_icons' do
      before do
        @event = create(:event, tag_list: %w[ruby pizza])
        @event2 = create(:event, tag_list: %w[no_image also_no_image])
        @untagged_event = Event.new
      end

      it 'renders nothing if no image tags' do
        expect(helper.display_tag_icons(@event2)).to eq ' '
      end

      it 'renders nothing if event has no tags' do
        expect(helper.display_tag_icons(@untagged_event)).to eq ''
      end

      it 'renders an image if the event tag has one associated' do
        expect(helper.display_tag_icons(@event)).to include 'img'
      end
    end
  end
end
