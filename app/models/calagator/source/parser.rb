# frozen_string_literal: true

require 'net/http'
require 'net/https'
require 'open-uri'

# == Source::Parser
#
# A hierarchy of classes that provide a way to parse different source formats and return hCalendar events.
# The base class for all format-specific parsers. Do not use instances of this class
# directly, use a subclass of Parser to do the parsing instead.
module Calagator
  class Source::Parser < Struct.new(:url, :source)
    # Return an Array of unsaved Event instances.
    def self.to_events(url: nil, source: nil)
      # Return events from the first parser that succeeds
      events = matched_parsers(url).lazy.collect do |parser|
        parser.new(url, source).to_events
      end.detect(&:present?)

      events || []
    end

    def self.matched_parsers(url)
      # start with the parser that matches the given URL
      parsers.sort_by do |parser|
        match = parser.url_pattern.present? && url.try(:match, parser.url_pattern)
        match ? 0 : 1
      end
    end
    private_class_method :matched_parsers

    cattr_accessor(:parsers) { Set.new }

    def self.inherited(subclass)
      parsers << subclass
    end

    class_attribute :label, :url_pattern

    # Returns an Array of sorted string labels for the parsers.
    def self.labels
      parsers.map { |p| p.label.to_s }.sort_by(&:downcase)
    end

    def self.read_url(url)
      RestClient.get(url).to_str
    rescue RestClient::Unauthorized
      raise Source::Parser::HttpAuthenticationRequiredError
    end

    def to_events
      raise NotImplementedError
    end

    def self.<=>(other)
      # use site-specific parsers first, then generics alphabetically
      if url_pattern && !other.url_pattern
        -1
      elsif !url_pattern && other.url_pattern
        1
      else
        label <=> other.label
      end
    end

    private

    def event_or_duplicate(event)
      duplicates = event.find_exact_duplicates
      if duplicates.present?
        duplicates.first.originator
      else
        event
      end
    end

    def venue_or_duplicate(venue)
      duplicates = venue.find_exact_duplicates
      if duplicates.present?
        duplicates.first.originator
      else
        venue_machine_tag_name = venue.tag_list.find do |tag_name|
          MachineTag.new(tag_name).venue?
        end
        matched_venue = Venue.tagged_with(venue_machine_tag_name).first

        if matched_venue.present?
          matched_venue.originator
        else
          venue
        end
      end
    end

    def to_events_api_helper(url, error_key = 'error')
      # Extract +event_id+ from :url using +url_pattern+.
      event_id = url[self.class.url_pattern, 1]
      return false unless event_id # Give up unless we find the identifier.

      # Get URL and params for using the API.
      url, params = *yield(event_id)

      # Get data from the API.
      data = RestClient.get(url, params: params, accept: 'json').to_str
      data = JSON.parse(data)

      # Stop if API tells us there's an error.
      raise Source::Parser::NotFound, error if error = data[error_key]

      data['event_id'] = event_id
      data
    end
  end
end

require 'calagator/source/parser/not_found'
require 'calagator/source/parser/ical'
require 'calagator/source/parser/hcal'
