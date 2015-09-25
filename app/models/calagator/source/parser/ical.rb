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

  VENUE_CONTENT_RE = /^BEGIN:VVENUE$.*?^END:VVENUE$/m

  # Override Source::Parser.read_url to handle "webcal" scheme addresses.
  def self.read_url(url)
    url.gsub!(/^webcal:/, 'http:')
    super
  end

  def to_events
    return false unless calendars
    events = calendars.flat_map(&:events).each do |event|
      event.source = source
    end
    dedup(events)
  end

  private

  def calendars
    @calendars ||= RiCal.parse_string(content).map do |calendar|
      VCalendar.new(calendar)
    end
  rescue Exception => exception
    return false if exception.message =~ /Invalid icalendar file/ # Invalid data, give up.
    raise # Unknown error, reraise
  end

  def content
    self.class.read_url(url).tap do |content|
      content.gsub! /\r\n/, "\n" # normalize line endings
      content.gsub! /;TZID=GMT:(.*)/, ':\1Z' # normalize timezones
    end
  end

  def dedup(events)
    events.map do |event|
      event = event_or_duplicate(event)
      event.venue = venue_or_duplicate(event.venue) if event.venue
      event
    end.uniq
  end

  class VCalendar < Struct.new(:calendar)
    def events
      calendar.events.map do |component|
        VEvent.new(component, self)
      end.reject(&:old?).map(&:to_event)
    end

    def venues
      calendar.to_s.scan(VENUE_CONTENT_RE)
    end
  end

  class VEvent < Struct.new(:component, :calendar)
    def old?
      cutoff = Time.now.yesterday
      (component.dtend || component.dtstart).to_time < cutoff
    end

    def to_event
      event = EventParser.new(component).to_event
      event.venue = VenueParser.new(vvenue, component.location).to_venue
      event
    end

    private

    def vvenue
      venues = calendar.venues
      # finding the event venue id - VVENUE=V0-001-001423875-1@eventful.com
      venue_uid = component.location_property.params["VVENUE"]
      # finding in the venues array an item matching the uid
      venue_uid ? venues.find{|venue| venue.match(/^UID:#{venue_uid}$/m)} : nil
    rescue => exception
      Rails.logger.info("Source::Parser::Ical.to_events : Failed to parse content_venue for event -- #{exception}")
      nil
    end
  end

  class EventParser < Struct.new(:component)
    def to_event
      Event.new({
        title:       component.summary,
        description: component.description,
        url:         component.url,
        start_time:  normalized_start_time(component),
        end_time:    normalized_end_time(component),
      })
    end

    private

    # Helper to set the start and end dates correctly depending on whether it's a floating or fixed timezone
    def normalized_start_time(component)
      if component.dtstart_property.tzid
        component.dtstart
      else
        Time.zone.parse(component.dtstart_property.value)
      end
    end

    # Helper to set the start and end dates correctly depending on whether it's a floating or fixed timezone
    def normalized_end_time(component)
      if component.dtstart_property.tzid
        component.dtend
      elsif component.dtend_property
        Time.zone.parse(component.dtend_property.value)
      elsif component.duration
        component.duration_property.add_to_date_time_value(normalized_start_time(component))
      else
        normalized_start_time(component)
      end
    end
  end

  # Return an Venue extracted from an iCalendar input.
  #
  # Arguments:
  # * value - String with iCalendar data to parse which contains a VVENUE item.
  # * fallback - String to use as the title for the location if the +value+ doesn't contain a VVENUE.
  class VenueParser < Struct.new(:value, :fallback)
    def to_venue
      venue = Venue.new

      # VVENUE entries are considered just Vcards,
      # treating them as such.
      if vcard_hash = vcard_hash_from_value(value)
        location = vcard_hash['GEO'].split(/;/).map(&:to_f)
        venue.attributes = {
          title:          vcard_hash['NAME'],
          street_address: vcard_hash['ADDRESS'],
          locality:       vcard_hash['CITY'],
          region:         vcard_hash['REGION'],
          postal_code:    vcard_hash['POSTALCODE'],
          country:        vcard_hash['COUNTRY'],
          latitude:       location.first,
          longitude:      location.last,
        }

      elsif fallback.present?
        venue.title = fallback
      else
        return nil
      end

      venue.geocode!

      venue
    end

    private

    def vcard_hash_from_value(value)
      value ||= ""
      return unless data = value.scan(VENUE_CONTENT_RE).first

      # Only use first vcard of a VVENUE
      vcard = RiCal.parse_string(data).first

      # Extract all properties, including non-standard ones, into an array of "KEY;meta-qualifier:value" strings
      vcard_lines = vcard.export_properties_to(StringIO.new(''))

      # Turn a String-like object into an Enumerable.
      vcard_lines = vcard_lines.respond_to?(:lines) ? vcard_lines.lines : vcard_lines

      hash_from_vcard_lines(vcard_lines)
    end

    VCARD_LINES_RE = /^(?<key>[^;]+?)(?<qualifier>;[^:]*?)?:(?<value>.*)$/

    # Return hash parsed from VCARD lines.
    #
    # Arguments:
    # * vcard_lines - Array of "KEY;meta-qualifier:value" strings.
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

end
