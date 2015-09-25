# == Source::Parser::Ical
#
# Reads iCalendar events.
#
# Example:
#   events = Source::Parser::Ical.to_events('http://appendix.23ae.com/calendars/AlternateHolidays.ics')
#
# Sample sources:
#   webcal://appendix.23ae.com/calendars/AlternateHolidays.ics
#   http://appendix.23ae.com/calendars/AlternateHolidays.ics
module Calagator

class Source::Parser::Ical < Source::Parser
  self.label = :iCalendar

  # Override Source::Parser.read_url to handle "webcal" scheme addresses.
  def self.read_url(url)
    url.gsub!(/^webcal:/, 'http:')
    super
  end

  def to_events
    return false unless vcalendars
    events = vcalendars.flat_map(&:vevents).reject(&:old?).map(&:to_event).each do |event|
      event.source = source
    end
    dedup(events)
  end

  private

  def vcalendars
    @vcalendars ||= VCalendar.parse(raw_ical)
  end

  def raw_ical
    self.class.read_url(url)
  end

  def dedup(events)
    events.map do |event|
      event = event_or_duplicate(event)
      event.venue = venue_or_duplicate(event.venue) if event.venue
      event
    end.uniq
  end

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
      ri_cal_calendar.to_s.scan(VENUE_CONTENT_RE).map do |raw_ical_venue|
        VVenue.new(raw_ical_venue)
      end
    end
  end

  class VEvent < Struct.new(:ri_cal_event, :vvenues)
    def old?
      cutoff = Time.now.yesterday
      (ri_cal_event.dtend || ri_cal_event.dtstart).to_time < cutoff
    end

    def to_event
      event = EventParser.new(self).to_event
      event.venue = VenueParser.new(vvenue, ri_cal_event.location).to_venue
      event
    end

    private

    def venue_uid
      ri_cal_event.location_property.try(:params).try(:[], "VVENUE")
    end

    def vvenue
      vvenues.find { |venue| venue.uid == venue_uid } if venue_uid
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

    private

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

  class EventParser < Struct.new(:vevent)
    def to_event
      Event.new({
        title:       vevent.ri_cal_event.summary,
        description: vevent.ri_cal_event.description,
        url:         vevent.ri_cal_event.url,
        start_time:  normalized_start_time(vevent.ri_cal_event),
        end_time:    normalized_end_time(vevent.ri_cal_event),
      })
    end

    private

    # Helper to set the start and end dates correctly depending on whether it's a floating or fixed timezone
    def normalized_start_time(ri_cal_event)
      if ri_cal_event.dtstart_property.tzid
        ri_cal_event.dtstart
      else
        Time.zone.parse(ri_cal_event.dtstart_property.value)
      end
    end

    # Helper to set the start and end dates correctly depending on whether it's a floating or fixed timezone
    def normalized_end_time(ri_cal_event)
      if ri_cal_event.dtstart_property.tzid
        ri_cal_event.dtend
      elsif ri_cal_event.dtend_property
        Time.zone.parse(ri_cal_event.dtend_property.value)
      elsif ri_cal_event.duration
        ri_cal_event.duration_property.add_to_date_time_value(normalized_start_time(ri_cal_event))
      else
        normalized_start_time(ri_cal_event)
      end
    end
  end

  # Return an Venue extracted from an iCalendar input.
  #
  # Arguments:
  # * value - String with iCalendar data to parse which contains a VVENUE item.
  # * fallback - String to use as the title for the location if the +value+ doesn't contain a VVENUE.
  class VenueParser < Struct.new(:vvenue, :fallback)
    def to_venue
      from_vvenue or from_fallback or return
    end

    private

    def from_vvenue
      return unless vvenue
      location = vvenue.geo.split(/;/).map(&:to_f)
      Venue.new({
        title:          vvenue.name,
        street_address: vvenue.address,
        locality:       vvenue.city,
        region:         vvenue.region,
        postal_code:    vvenue.postalcode,
        country:        vvenue.country,
        latitude:       location.first,
        longitude:      location.last,
      }) do |venue|
        venue.geocode!
      end
    end

    def from_fallback
      return unless fallback.present?
      Venue.new(title: fallback)
    end
  end
end

end
