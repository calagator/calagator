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

# == Source
#
# A model that represents a source of events data, such as feeds for hCal, iCal, etc.
require 'calagator/decode_html_entities_hack'
require 'paper_trail'
require 'loofah-activerecord'
require 'loofah/activerecord/xss_foliate'

module Calagator
  class Source < ApplicationRecord
    self.table_name = 'sources'

    validate :assert_url

    has_many :events,  dependent: :destroy
    has_many :venues,  dependent: :destroy

    scope :listing, -> { order('created_at DESC') }

    has_paper_trail

    xss_foliate
    include DecodeHtmlEntitiesHack

    # Create events for this source. Returns the events created. URL must be set
    # for this source for this to work.
    def create_events!
      save!
      to_events.select { |event| event.valid? && !event.old? }.each(&:save!)
    end

    # Normalize the URL.
    def url=(value)
      url = URI.parse(value.strip)
      unless %w[http https ftp].include?(url.scheme) || url.scheme.nil?
        url.scheme = 'http'
      end
      self[:url] = url.scheme.nil? ? 'http://' + value.strip : url.to_s
    rescue URI::InvalidURIError
      false
    end

    # Returns an Array of Event objects that were read from this source.
    def to_events
      raise ActiveRecord::RecordInvalid, self unless valid?

      self.imported_at = Time.now.in_time_zone
      Source::Parser.to_events(url: url, source: self)
    end

    # Return the name of the source, which can be its title or URL.
    def name
      [title, url].detect(&:present?)
    end

    private

    # Ensure that the URL for this source is valid.
    def assert_url
      URI.parse(url)
    rescue URI::InvalidURIError
      errors.add :url, 'has invalid format'
      false
    end
  end
end
