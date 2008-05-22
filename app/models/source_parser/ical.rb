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

    CALENDAR_CONTENT_RE    = /^BEGIN:VCALENDAR.*?^END:VCALENDAR/m
    EVENT_CONTENT_RE       = /^BEGIN:VEVENT.*?^END:VEVENT/m
    EVENT_DTSTART_RE       = /^DTSTART.*?:([^\r\n$]+)/m
    VENUE_CONTENT_RE       = /^BEGIN:VVENUE$.*?^END:VVENUE$/m
    VENUE_CONTENT_BEGIN_RE = /^BEGIN:VVENUE$/m
    VENUE_CONTENT_END_RE   = /^END:VVENUE$/m

    # Return an Array of AbstractEvent instances extracted from an iCalendar input.
    #
    # Options:
    # * :url -- URL of iCalendar data to import
    # * :content -- String of iCalendar data to import
    # * :skip_old -- Should old events be skipped? Default is true.
    def self.to_abstract_events(opts={})
      # Skip old events by default
      opts[:skip_old] = true unless opts[:skip_old] == false
      cutoff = Time.now.yesterday

      content = content_for(opts)
      content_calendars = content.scan(CALENDAR_CONTENT_RE)

      events = []
      for content_calendar in content_calendars
        for content_event in content_calendar.scan(EVENT_CONTENT_RE)
          # Skip old events before handing them to VPIM
          if opts[:skip_old]
            if match = content_event.match(EVENT_DTSTART_RE)
              dtstart = match[1]
              time = Time.parse(dtstart)
              ### puts "matched: #{dtstart} / #{time} / #{cutoff}"
              if time < cutoff
                ### puts "Skipping event: #{dtstart}"
                next 
              end
            end
          end

          components = Vpim::Icalendar.decode("BEGIN:VCALENDAR\n"+content_event+"\nEND:VCALENDAR\n").first.components
          for component in components
            event = AbstractEvent.new
            event.start_time = component.dtstart
            event.title = component.summary
            event.description = component.description
            event.end_time = component.dtend
            event.url = component.url
            event.location = to_abstract_location(content_calendar, :fallback => component.location)
           events << event
          end
        end
      end
      return events
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

      # The Vpim libary doesn't understand that Vvenue entries are just Vcards,
      # so transform the content to trick it into treating them as such.
      if vcard_content = value.scan(VENUE_CONTENT_RE).first
        vcard_content.gsub!(VENUE_CONTENT_BEGIN_RE, 'BEGIN:VCARD')
        vcard_content.gsub!(VENUE_CONTENT_END_RE, 'END:VCARD')

        begin
          # TODO What if there is more than one vcard in the vcalendar?!
          vcards = Vpim::Vcard.decode(vcard_content)
          raise ArgumentError, "Wrong number of vcards" unless vcards.size == 1
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
          # Exceptional state will be handled below
        end
      end

      if opts[:fallback].blank?
        return nil
      else
        a.title = opts[:fallback]
        return a
      end
    end
  end
end

