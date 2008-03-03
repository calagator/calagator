# Loads vpim from vendor/gems
require 'vpim/icalendar'
require 'vpim/vcard'

class SourceParser # :nodoc:
  # == SourceParser::Ical
  #
  # Reads iCalendar events.
  #
  # Example:
  #   abstract_events = SourceParser::Ical.to_abstract_events('http://upcoming.yahoo.com/calendar/v2/event/349225')
  #
  # Sample sources:
  #   http://upcoming.yahoo.com/calendar/v2/event/349225
  #   webcal://appendix.23ae.com/calendars/AlternateHolidays.ics
  #   http://appendix.23ae.com/calendars/AlternateHolidays.ics
  class Ical < Base
    label :iCalendar

    # Override Base::read_url to handle "webcal" scheme addresses.
    def self.read_url(url)
      super(url.gsub(/^webcal:/, 'http:'))
    end

    # Return an Array of AbstractEvent instances extracted from an iCalendar input.
    #
    # Options:
    # * :url -- URL of iCalendar data to import
    def self.to_abstract_events(opts={})
      content = read_url(opts[:url])

      content_calendars = content.scan(/^BEGIN:VCALENDAR.*^END:VCALENDAR/m)
      event_results = content_calendars.map do |content_calendar|
        events = Vpim::Icalendar.decode(content_calendar).first.components.map do |component|
          event = AbstractEvent.new

          event.title = component.summary
          event.description = component.description
          event.start_time = component.dtstart
          event.url = component.url
          event.location = to_abstract_location(content_calendar, :fallback => component.location)
          event
        end
      end
      return event_results.flatten
    end

    # Return an AbstractLocation extracted from an iCalendar input.
    #
    # Arguments:
    # * value - String with iCalendar data to parse which contains a Vvenue item.
    #
    # Options:
    # * :fallback - String to use as the title for the location if the +value+ doesn't contain a Vvenue.
    def self.to_abstract_location(value, opts={})
      a = AbstractLocation.new

      # Function returns an AbstractLocation with the fallback string as its
      # title, or a nil if no fallback string was given.
      fallback_or_nil = lambda {
        if opts[:fallback].blank?
          nil
        else
          a.title = opts[:fallback]
          a
        end
      }

      # The Vpim libary doesn't understand that Vvenue entries are just Vcards,
      # so transform the content to trick it into treating them as such.
      if vcard_content = value.scan(/^BEGIN:VVENUE$.*^END:VVENUE$/m).first
        vcard_content.gsub!(/^BEGIN:VVENUE$/m, 'BEGIN:VCARD')
        vcard_content.gsub!(/^END:VVENUE$/m, 'END:VCARD')

        begin
          # TODO What if there is more than one vcard in the vcalendar?!
          vcards = Vpim::Vcard.decode(vcard_content)
          raise ArgumentError, "Wrong number of vcards" if vcards.size != 1
          vcard = vcards.first

          a.title = vcard['name']
          a.street_address = vcard['address']
          a.locality = vcard['city']
          a.region = vcard['region']
          a.postal_code = vcard['postalcode']
          a.country = vcard['country']

          a.latitude, a.longitude = vcard['geo'].split(/;/).map(&:to_f)

          return a
        rescue Vpim::InvalidEncodingError, ArgumentError, RuntimeError
          return fallback_or_nil.call
        end
      else
        return fallback_or_nil.call
      end
    end
  end
end

