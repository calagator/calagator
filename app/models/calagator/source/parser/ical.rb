require "calagator/vcalendar"

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
    current_vevents = vcalendars.flat_map(&:vevents).reject(&:old?)
    current_events = current_vevents.map { |vevent| to_event(vevent) }
    dedup(current_events)
  end

  private

  def vcalendars
    @vcalendars ||= VCalendar.parse(raw_ical)
  end

  def raw_ical
    self.class.read_url(url)
  end

  def to_event(vevent)
    event = EventMapper.new(vevent).to_event
    event.venue = VenueMapper.new(vevent.vvenue, vevent.location).to_venue
    event.source = source
    event
  end

  def dedup(events)
    events.map do |event|
      event = event_or_duplicate(event)
      event.venue = venue_or_duplicate(event.venue) if event.venue
      event
    end.uniq
  end

  # Converts a VEvent instance into an Event
  class EventMapper < Struct.new(:vevent)
    def to_event
      Event.new({
        title:       vevent.summary,
        description: vevent.description,
        url:         vevent.url,
        start_time:  vevent.start_time,
        end_time:    vevent.end_time,
      })
    end
  end

  # Converts a VVenue instance into a Venue
  class VenueMapper < Struct.new(:vvenue, :fallback)
    def to_venue
      from_vvenue or from_fallback or return
    end

    private

    def from_vvenue
      return unless vvenue
      Venue.new({
        title:          vvenue.name,
        street_address: vvenue.address,
        locality:       vvenue.city,
        region:         vvenue.region,
        postal_code:    vvenue.postalcode,
        country:        vvenue.country,
        latitude:       vvenue.latitude,
        longitude:      vvenue.longitude,
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
