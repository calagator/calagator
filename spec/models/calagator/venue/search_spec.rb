# frozen_string_literal: true

require 'spec_helper'

module Calagator
  describe Venue::Search, type: :model do
    describe '#venues' do
      before do
        @open_venue = FactoryBot.create(:venue, title: 'Open Town', description: 'baz', wifi: false, tag_list: %w[foo])
        @closed_venue = FactoryBot.create(:venue, title: 'Closed Down', closed: true, wifi: false, tag_list: %w[bar])
        @wifi_venue = FactoryBot.create(:venue, title: 'Internetful', wifi: true, tag_list: %w[foo bar])
      end

      describe 'with no parameters' do
        subject { described_class.new }

        it 'does not include closed venues' do
          expect(subject.venues).to match_array([@open_venue, @wifi_venue])
        end

        it 'does not declare results' do
          expect(subject).not_to be_results
        end
      end

      describe 'and showing all venues' do
        it 'includes closed venues when asked to with the include_closed parameter' do
          subject = described_class.new all: '1', include_closed: '1'
          expect(subject.venues).to match_array([@open_venue, @closed_venue, @wifi_venue])
        end

        it 'includes ONLY closed venues when asked to with the closed parameter' do
          subject = described_class.new all: '1', closed: '1'
          expect(subject.venues).to eq([@closed_venue])
        end

        it 'declares results' do
          subject = described_class.new all: '1'
          expect(subject).to be_results
        end
      end

      describe 'when searching' do
        describe 'for public wifi (and no keyword)' do
          it 'onlies include results with public wifi' do
            subject = described_class.new query: '', wifi: '1'
            expect(subject.venues).to eq([@wifi_venue])
          end

          it 'declares results' do
            subject = described_class.new query: '', wifi: '1'
            expect(subject).to be_results
          end
        end

        describe 'when searching by keyword' do
          it 'finds venues by title' do
            subject = described_class.new query: 'Open Town'
            expect(subject.venues).to eq([@open_venue])
          end

          it 'finds venues by description' do
            subject = described_class.new query: 'baz'
            expect(subject.venues).to eq([@open_venue])
          end

          describe 'and requiring public wifi' do
            it 'does not find venues without public wifi' do
              subject = described_class.new query: 'baz', wifi: '1'
              expect(subject.venues).to be_empty
            end
          end

          it 'declares results' do
            subject = described_class.new query: 'Open Town'
            expect(subject).to be_results
          end
        end
      end

      it 'is able to return events matching specific tag' do
        subject = described_class.new tag: 'foo'
        expect(subject.venues).to match_array([@open_venue, @wifi_venue])
      end

      it 'declares results' do
        subject = described_class.new tag: 'foo'
        expect(subject).to be_results
      end

      describe 'handling exceptions' do
        subject(:venue_search) { described_class.new }

        before { allow(Venue).to receive(:non_duplicates).and_raise(ActiveRecord::StatementInvalid, 'bad times') }

        before { venue_search.venues }

        it 'sets a failure message' do
          expect(venue_search.failure_message).to eq('There was an error completing your search.')
        end

        it 'is a hard failure' do
          expect(venue_search).to be_hard_failure
        end
      end
    end
  end
end
