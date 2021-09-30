# frozen_string_literal: true

require 'spec_helper'

module Calagator
  describe Venue, type: :model do
    shared_examples_for '#search' do
      it 'returns everything when searching by empty string' do
        venue1 = create(:venue)
        venue2 = create(:venue)
        expect(described_class.search('')).to match_array([venue1, venue2])
      end

      it 'searches venue titles by substring' do
        venue1 = create(:venue, title: 'wtfbbq')
        venue2 = create(:venue, title: 'zomg!')
        expect(described_class.search('zomg')).to eq([venue2])
      end

      it 'searches venue descriptions by substring' do
        venue1 = create(:venue, description: 'wtfbbq')
        venue2 = create(:venue, description: 'zomg!')
        expect(described_class.search('zomg')).to eq([venue2])
      end

      it 'searches venue tags by exact match' do
        venue1 = create(:venue) { |venue| venue.tag_list.add(%w[wtf bbq zomg]) }
        venue2 = create(:venue) { |venue| venue.tag_list.add(%w[wtf bbq omg]) }
        expect(described_class.search('omg')).to eq([venue2])
      end

      it 'searches case-insensitively' do
        venue1 = create(:venue, title: 'WTFBBQ')
        venue2 = create(:venue, title: 'ZOMG!')
        expect(described_class.search('zomg')).to eq([venue2])
      end

      it 'sorts by title' do
        venue2 = create(:venue, title: 'zomg')
        venue1 = create(:venue, title: 'omg')
        expect(described_class.search('', order: 'name')).to eq([venue1, venue2])
      end

      it 'can limit to venues with wifi' do
        venue1 = create(:venue, wifi: false)
        venue2 = create(:venue, wifi: true)
        expect(described_class.search('', wifi: true)).to eq([venue2])
      end

      it 'excludes closed venues' do
        venue1 = create(:venue, closed: true)
        venue2 = create(:venue, closed: false)
        expect(described_class.search('')).to eq([venue2])
      end

      it 'can include closed venues' do
        venue1 = create(:venue, closed: true)
        venue2 = create(:venue, closed: false)
        expect(described_class.search('', include_closed: true)).to match_array([venue1, venue2])
      end

      it 'can limit number of venues' do
        create_list(:venue, 2)
        expect(described_class.search('', limit: 1).count).to eq(1)
      end

      it 'does not search multiple terms' do
        venue2 = create(:venue, title: 'zomg')
        venue1 = create(:venue, title: 'omg')
        expect(described_class.search('zomg omg')).to eq([])
      end

      it 'ANDs terms together to narrow search results' do
        venue2 = create(:venue, title: 'zomg omg')
        venue1 = create(:venue, title: 'zomg cats')
        expect(described_class.search('zomg omg')).to eq([venue2])
      end
    end

    describe 'Sql' do
      around do |example|
        original = Venue::SearchEngine.kind
        Venue::SearchEngine.kind = :sql
        example.run
        Venue::SearchEngine.kind = original
      end

      it_behaves_like '#search'

      it 'is using the sql search engine' do
        expect(Venue::SearchEngine.kind).to eq(:sql)
      end
    end

    describe 'Sunspot' do
      around do |example|
        server_running = begin
          # Try opening the configured port. If it works, it's running.
          TCPSocket.new('127.0.0.1', Sunspot::Rails.configuration.port).close
          true
                         rescue Errno::ECONNREFUSED
                           false
        end

        if server_running
          Event::SearchEngine.use(:sunspot)
          Venue::SearchEngine.use(:sunspot)
          Event.reindex
          described_class.reindex
          example.run
        else
          pending 'Solr not running. Start with `rake sunspot:solr:start RAILS_ENV=test`'
        end
      end

      it_behaves_like '#search'

      it 'is using the sunspot search engine' do
        expect(Venue::SearchEngine.kind).to eq(:sunspot)
      end
    end
  end
end
