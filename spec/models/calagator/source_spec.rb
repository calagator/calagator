# frozen_string_literal: true

# == Schema Information
#
# Table name: sources
#
#  id          :integer          not null, primary key
#  imported_at :datetime
#  title       :string
#  url         :string
#  created_at  :datetime
#  updated_at  :datetime
#
require 'spec_helper'

module Calagator
  describe Source, 'in general', type: :model do
    before do
      @event = mock_model(Event,
                          title: 'Title',
                          description: 'Description',
                          url: 'http://my.url/',
                          start_time: Time.now.in_time_zone + 1.day,
                          end_time: nil,
                          old?: false,
                          venue: nil,
                          duplicate_of_id: nil)
    end

    it 'creates events for source from URL' do
      expect(@event).to receive(:save!)

      source = described_class.new(url: 'http://my.url/')
      expect(source).to receive(:to_events).and_return([@event])
      expect(source.create_events!).to eq [@event]
    end

    it 'fails to create events for invalid sources' do
      source = described_class.new(url: '\not valid/')
      expect { source.to_events }.to raise_error(ActiveRecord::RecordInvalid, /Url has invalid format/i)
    end
  end

  describe Source, 'when reading name', type: :model do
    before do
      @title = 'title'
      @url = 'http://my.url/'
    end

    before do
      @source = described_class.new
    end

    it 'returns nil if no title is available' do
      expect(@source.name).to be_nil
    end

    it 'uses title if available' do
      @source.title = @title
      expect(@source.name).to eq @title
    end

    it 'uses URL if available' do
      @source.url = @url
      expect(@source.name).to eq @url
    end

    it 'prefers to use title over URL if both are available' do
      @source.title = @title
      @source.url = @url

      expect(@source.name).to eq @title
    end
  end

  describe Source, 'when parsing URLs', type: :model do
    before do
      @http_url = 'http://upcoming.yahoo.com/event/390164/'
      @ical_url = 'webcal://upcoming.yahoo.com/event/390164/'
      @base_url = 'upcoming.yahoo.com/event/390164/'
    end

    before do
      @source = described_class.new
    end

    it 'does not modify supported url schemes' do
      @source.url = @http_url

      expect(@source.url).to eq @http_url
    end

    it 'substitutes http for unsupported url schemes' do
      @source.url = @ical_url

      expect(@source.url).to eq @http_url
    end

    it 'adds the http prefix to urls without one' do
      @source.url = @base_url

      expect(@source.url).to eq @http_url
    end

    it 'strips leading and trailing whitespace from URL' do
      source = described_class.new
      source.url = "     #{@http_url}     "
      expect(source.url).to eq @http_url
    end

    it 'is invalid if given invalid URL' do
      source = described_class.new
      source.url = '\O.o/'
      expect(source.url).to be_nil
      expect(source).not_to be_valid
    end
  end
end
