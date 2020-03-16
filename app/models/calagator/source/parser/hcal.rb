# frozen_string_literal: true

# == Source::Parser::Hcal
#
# Reads hCalendar events.

require 'microformats'

module Calagator
  class Source::Parser::Hcal < Source::Parser
    self.label = :hCalendar

    EVENT_TO_HCALENDAR_FIELD_MAP = {
      title: :name,
      description: :description,
      start_time: :start,
      end_time: :end,
      url: :url,
      venue: :location
    }.freeze

    def to_events
      hcals.map do |hcal|
        event = Event.new
        event.source = source
        EVENT_TO_HCALENDAR_FIELD_MAP.each do |field, hcal_field|
          next unless hcal.respond_to?(hcal_field)
          next unless value = decoded_field(hcal, hcal_field)

          event.send "#{field}=", value
        end
        event_or_duplicate(event)
      end.uniq do |event|
        [event.attributes, event.venue.try(:attributes)]
      end
    end

    private

    def decoded_field(hcal, hcal_field)
      return unless raw_field = hcal.send(hcal_field)

      decoded_field = case hcal_field
                      when :start, :end
                        Time.parse(raw_field).in_time_zone
                      when :location
                        to_venue(raw_field)
                      else
                        raw_field
      end
    end

    VENUE_TO_HCARD_FIELD_MAP = {
      title: :name,
      telephone: :tel,
      email: :email,
      description: :note
    }.freeze

    # Return a Venue.
    #
    # Options:
    # * :value -- hCard or string location
    def to_venue(value)
      venue = Venue.new
      venue.source = source
      case value
      when String
        venue.title = value
      when Microformats::ParserResult
        assign_fields(venue, value)
        assign_geo(venue, value) if value.respond_to?(:geo)
        assign_address(venue, value) if value.respond_to?(:adr)
      end
      venue.geocode!
      venue_or_duplicate(venue)
    end

    def assign_fields(venue, raw)
      VENUE_TO_HCARD_FIELD_MAP.each do |field, hcal_field|
        venue[field] = raw.send(hcal_field) if raw.respond_to?(hcal_field)
      end
    end

    def assign_geo(venue, raw)
      %w[latitude longitude].each do |field|
        venue[field] = raw.geo.send(field) if raw.geo.respond_to?(field)
      end
    end

    def assign_address(venue, raw)
      attributes = %w[street_address locality region country_name postal_code].each_with_object({}) do |field, attributes|
        attributes[field] = raw.adr.send(field) if raw.adr.respond_to?(field)
      end

      attributes['country'] = attributes.delete('country_name')
      if attributes['postal_code']
        attributes['postal_code'] = attributes['postal_code'].to_s
      end
      venue.attributes = attributes
    end

    def hcals
      Microformats.parse(url).items.select { |item| item.type == 'h-event' }
    end
  end
end
