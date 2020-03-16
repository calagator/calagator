# frozen_string_literal: true

require 'spec_helper'

describe ActsAsTaggableOn::Tag, type: :model do
  describe 'handling machine tags' do
    context 'when valid' do
      subject do
        described_class.new(name: 'meetup:group=1234')
      end

      it 'parses a machine tag into components' do
        expect(subject.machine_tag.namespace).to eq 'meetup'
        expect(subject.machine_tag.predicate).to eq 'group'
        expect(subject.machine_tag.value).to eq '1234'
      end

      it 'generates a url for supported namespaces/predicates' do
        expect(subject.machine_tag.url).to eq 'http://www.meetup.com/1234'
      end

      it "redirects to 'defunct' page with archive url as query param when using a defunct provider" do
        @event = FactoryBot.create :event, tag_list: 'upcoming:event=1234'
        event_date = @event.start_time.strftime('%Y%m%d')
        expect(@event.tags.last.machine_tag.url).to eq "http://my-calagator.org/defunct?url=https://web.archive.org/web/#{event_date}/http://upcoming.yahoo.com/event/1234"
      end

      it 'redirects correctly for venue tags also' do
        @venue = FactoryBot.create :venue, tag_list: 'upcoming:venue=1234'
        venue_date = @venue.created_at.strftime('%Y%m%d')
        expect(@venue.tags.last.machine_tag.url).to eq "http://my-calagator.org/defunct?url=https://web.archive.org/web/#{venue_date}/http://upcoming.yahoo.com/venue/1234"
      end
    end

    describe '#venue?' do
      it 'knows when its a venue' do
        subject = described_class.new(name: 'upcoming:venue=1234')
        expect(subject.machine_tag).to be_venue
      end

      it 'knows when its not a venue' do
        subject = described_class.new(name: 'meetup:group=1234')
        expect(subject.machine_tag).not_to be_venue
      end
    end

    context 'when invalid' do
      subject do
        described_class.new(name: 'not a machine tag')
      end

      it 'has empty properties when the tag is not a machine tag' do
        expect(subject.machine_tag.url).to be_nil
        expect(subject.machine_tag.namespace).to be_nil
        expect(subject.machine_tag.predicate).to be_nil
        expect(subject.machine_tag.value).to be_nil
      end
    end
  end
end
