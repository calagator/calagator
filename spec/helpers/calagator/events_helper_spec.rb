# frozen_string_literal: true

require 'spec_helper'

module Calagator
  describe EventsHelper, type: :helper do
    describe '#events_sort_link' do
      it 'renders a sorting link with the field for the supplied key' do
        params.merge! action: 'index', controller: 'calagator/events'
        expect(helper.events_sort_link('score')).to eq(%(<a href="/events?order=score">Relevance</a>))
      end

      it 'removes any existing order if no key is entered' do
        params.merge! action: 'index', controller: 'calagator/events', order: 'score'
        expect(helper.events_sort_link(nil)).to eq(%(<a href="/events">Default</a>))
      end
    end

    describe '#events_sort_label' do
      it 'returns nil without arguments' do
        expect(helper.events_sort_label(nil)).to be_nil
      end

      it 'returns string for a string key' do
        expect(helper.events_sort_label('score')).to eq(' by <strong>Relevance.</strong>')
      end

      it 'returns string for a symbol key' do
        expect(helper.events_sort_label(:score)).to eq(' by <strong>Relevance.</strong>')
      end

      it 'uses the label Date when using a tag' do
        assign :tag, ActsAsTaggableOn::Tag.new
        expect(helper.events_sort_label(nil)).to eq(' by <strong>Date.</strong>')
      end
    end

    describe '#today_tomorrow_or_weekday' do
      it 'displays day of the week' do
        event = Event.new start_time: '2010-01-01'
        expect(helper.today_tomorrow_or_weekday(event)).to eq('Friday')
      end

      it "displays tomorrow as 'Tomorrow'" do
        event = Event.new start_time: '2010-01-01', end_time: 1.day.from_now
        expect(helper.today_tomorrow_or_weekday(event)).to eq('Started Friday')
      end
    end

    describe '#google_events_subscription_link' do
      def method(*args)
        helper.google_events_subscription_link(*args)
      end

      it 'fails if given unknown options' do
        expect { method(omg: :kittens) }.to raise_error ArgumentError
      end

      it 'generates a default link' do
        expect(method).to eq 'https://www.google.com/calendar/render?cid=webcal%3A%2F%2Ftest.host%2Fevents.ics'
      end

      it 'generates a search link' do
        expect(method(query: 'my query')).to eq 'https://www.google.com/calendar/render?cid=webcal%3A%2F%2Ftest.host%2Fevents%2Fsearch.ics%3Fquery%3Dmy%2Bquery'
      end

      it 'generates a tag link' do
        expect(method(tag: 'mytag')).to eq 'https://www.google.com/calendar/render?cid=webcal%3A%2F%2Ftest.host%2Fevents%2Fsearch.ics%3Ftag%3Dmytag'
      end
    end

    describe '#icalendar_feed_link' do
      def method(*args)
        helper.icalendar_feed_link(*args)
      end

      it 'fails if given unknown options' do
        expect { method(omg: :kittens) }.to raise_error ArgumentError
      end

      it 'generates a default link' do
        expect(method).to eq 'webcal://test.host/events.ics'
      end

      it 'generates a search link' do
        expect(method(query: 'my query')).to eq 'webcal://test.host/events/search.ics?query=my+query'
      end

      it 'generates a tag link' do
        expect(method(tag: 'mytag')).to eq 'webcal://test.host/events/search.ics?tag=mytag'
      end
    end

    describe '#icalendar_export_link' do
      def method(*args)
        helper.icalendar_export_link(*args)
      end

      it 'fails if given unknown options' do
        expect { method(omg: :kittens) }.to raise_error ArgumentError
      end

      it 'generates a default link' do
        expect(method).to eq 'http://test.host/events.ics'
      end

      it 'generates a search link' do
        expect(method(query: 'my query')).to eq 'http://test.host/events/search.ics?query=my+query'
      end

      it 'generates a tag link' do
        expect(method(tag: 'mytag')).to eq 'http://test.host/events/search.ics?tag=mytag'
      end
    end

    describe '#atom_feed_link' do
      def method(*args)
        helper.atom_feed_link(*args)
      end

      it 'fails if given unknown options' do
        expect { method(omg: :kittens) }.to raise_error ArgumentError
      end

      it 'generates a default link' do
        expect(method).to eq 'http://test.host/events.atom'
      end

      it 'generates a search link' do
        expect(method(query: 'my query')).to eq 'http://test.host/events/search.atom?query=my+query'
      end

      it 'generates a tag link' do
        expect(method(tag: 'mytag')).to eq 'http://test.host/events/search.atom?tag=mytag'
      end
    end

    describe '#tweet_text' do
      it 'contructs a tweet' do
        event = create(:event,
                                  title: 'hip and/or hop',
                                  start_time: '2010-01-01 12:00:00',
                                  end_time: '2010-01-02 12:00:00')
        event.venue = create(:venue, title: 'holocene')
        expect(tweet_text(event)).to eq('hip and/or hop - 12:00PM 01.01.2010 @ holocene')
      end

      it 'crops it at 140 characters' do
        event = create(:event,
                                  title: 'hip and/or hop, hip and/or hop, hip and/or hop, hip and/or hop, hip and/or hop, hip and/or hop',
                                  start_time: '2010-01-01 12:00:00',
                                  end_time: '2010-01-02 12:00:00')
        event.venue = create(:venue, title: 'holocene')
        expect(tweet_text(event)).to eq('hip and/or hop, hip and/or hop, hip and/or hop, hip and/or hop, hip and/or hop, h... - 12:00PM 01.01.2010 @ holocene')
      end
    end

    describe 'sorting labels' do
      it 'displays human-friendly label for a known value' do
        expect(helper.sorting_label_for('name')).to eq 'Event Name'
      end

      it 'displays a default label' do
        expect(helper.sorting_label_for(nil)).to eq 'Relevance'
      end

      it 'displays a different default label when searching by tag' do
        expect(helper.sorting_label_for(nil, true)).to eq 'Date'
      end
    end
  end
end
