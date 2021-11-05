# frozen_string_literal: true

require 'spec_helper'

module Calagator
  describe Event::Cloner do
    describe 'when cloning' do
      subject do
        described_class.clone(original)
      end

      let :original do
        build(:event,
              id: 42,
              start_time: Time.zone.parse('2008-01-19 10:00:00'),
              end_time: Time.zone.parse('2008-01-19 17:00:00'),
              venue_details: 'Details',
              tag_list: 'foo, bar, baz')
      end

      it { is_expected.to be_new_record }
      its(:id) { is_expected.to be_nil }

      describe '#start_time' do
        it 'equals todays date with the same time' do
          subject.start_time.to_date.should == Date.today
          subject.start_time.hour.should == original.start_time.hour
          subject.start_time.min.should == original.start_time.min
        end
      end

      describe '#end_time' do
        it 'equals todays date with the same time' do
          subject.end_time.to_date.should == Date.today
          subject.end_time.hour.should == original.end_time.hour
          subject.end_time.min.should == original.end_time.min
        end
      end

      %w[title description url venue_id venue_details tag_list].each do |field|
        its(field) { is_expected.to eq original.send(field) }
      end
    end
  end
end
