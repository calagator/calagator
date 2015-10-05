require "ri_cal"

module Calagator
  class VCalendar < Struct.new(:ri_cal_calendar)
    def self.parse(raw_ical)
      raw_ical.gsub! /\r\n/, "\n" # normalize line endings
      raw_ical.gsub! /;TZID=GMT:(.*)/, ':\1Z' # normalize timezones

      RiCal.parse_string(raw_ical).map do |ri_cal_calendar|
        VCalendar.new(ri_cal_calendar)
      end

    rescue Exception => exception
      return false if exception.message =~ /Invalid icalendar file/ # Invalid data, give up.
      raise # Unknown error, reraise
    end

    def vevents
      ri_cal_calendar.events.map do |ri_cal_event|
        VEvent.new(ri_cal_event, vvenues)
      end
    end

    VENUE_CONTENT_RE = /^BEGIN:VVENUE$.*?^END:VVENUE$/m

    def vvenues
      @vvenues ||= ri_cal_calendar.to_s.scan(VENUE_CONTENT_RE).map do |raw_ical_venue|
        VVenue.new(raw_ical_venue)
      end
    end
  end

  class VEvent < Struct.new(:ri_cal_event, :vvenues)
    def old?
      cutoff = Time.now.yesterday
      (ri_cal_event.dtend || ri_cal_event.dtstart).to_time < cutoff
    end

    delegate :location, :summary, :description, :url, to: :ri_cal_event

    # translate the start and end dates correctly depending on whether it's a floating or fixed timezone

    def start_time
      if ri_cal_event.dtstart_property.tzid
        ri_cal_event.dtstart
      else
        Time.zone.parse(ri_cal_event.dtstart_property.value)
      end
    end

    def end_time
      if ri_cal_event.dtstart_property.tzid
        ri_cal_event.dtend
      elsif ri_cal_event.dtend_property
        Time.zone.parse(ri_cal_event.dtend_property.value)
      elsif ri_cal_event.duration
        ri_cal_event.duration_property.add_to_date_time_value(start_time)
      else
        start_time
      end
    end

    def vvenue
      vvenues.find { |venue| venue.uid == venue_uid } if venue_uid
    end

    private

    def venue_uid
      ri_cal_event.location_property.try(:params).try(:[], "VVENUE")
    end
  end

  class VVenue < Struct.new(:raw_ical_venue)
    def uid
      raw_ical_venue.match(/^UID:(?<uid>.+)$/)[:uid]
    end

    def method_missing(method, *args, &block)
      vcard_hash_key = method.to_s.upcase
      return vcard_hash[vcard_hash_key] if vcard_hash.has_key?(vcard_hash_key)
      super
    end

    def respond_to?(method, include_private = false)
      vcard_hash_key = method.to_s.upcase
      vcard_hash.has_key?(vcard_hash_key) || super
    end

    def latitude
      geo_latlng.first
    end

    def longitude
      geo_latlng.last
    end

    private

    def geo_latlng
      return [] unless geo
      geo.split(/;/).map(&:to_f)
    end

    def vcard_hash
      # Only use first vcard of a VVENUE
      vcard = RiCal.parse_string(raw_ical_venue).first

      # Extract all properties into an array of "KEY;meta-qualifier:value" strings
      vcard_lines = vcard.export_properties_to(StringIO.new(''))

      hash_from_vcard_lines(vcard_lines)
    end

    VCARD_LINES_RE = /^(?<key>[^;]+?)(?<qualifier>;[^:]*?)?:(?<value>.*)$/

    def hash_from_vcard_lines(vcard_lines)
      vcard_lines.reduce({}) do |vcard_hash, vcard_line|
        vcard_line.match(VCARD_LINES_RE) do |match|
          vcard_hash[match[:key]] ||= match[:value]
        end
        vcard_hash
      end
    end
  end
end
