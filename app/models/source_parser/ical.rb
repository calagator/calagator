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
    EVENT_DTEND_RE         = /^DTEND.*?:([^\r\n$]+)/m
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

      content = content_for(opts).gsub(/\r\n/, "\n")
      content_calendars = content.scan(CALENDAR_CONTENT_RE)

      # FIXME Upcoming's iCalendar no longer includes newlines, so everything gets mashed into a single, long paragraph.

      returning([]) do |events|
        for content_calendar in content_calendars
          content_venues = content_calendar.scan(VENUE_CONTENT_RE)

          content_calendar.scan(EVENT_CONTENT_RE).each_with_index do |content_event, index|
            # Skip old events before handing them to VPIM
            if opts[:skip_old]
              if start_match = content_event.match(EVENT_DTSTART_RE)
                start_time = Time.parse(start_match[1])

                end_match = content_event.match(EVENT_DTEND_RE)
                end_time = end_match ? Time.parse(end_match[1]) : nil

                next if (end_time || start_time) < cutoff
              end
            end

            components = Vpim::Icalendar.decode(%{BEGIN:VCALENDAR\n#{content_event}\nEND:VCALENDAR\n}).first.components
            raise TypeError, "Got multiple components for a single event" unless components.size == 1
            component = components.first

            event             = AbstractEvent.new
            event.start_time  = component.dtstart
            event.title       = component.summary
            event.description = component.description
            event.end_time    = component.dtend
            event.url         = component.url

            content_venue = \
              begin
                if content_calendar.match(%r{VALUE=URI:http://upcoming.yahoo.com/})
                  # Special handling for Upcoming, where each event maps 1:1 to a venue
                  content_venues[index]
                else
                  begin
                    location_field = component.fields.find{|t| t.respond_to?(:name) && t.name.upcase == "LOCATION"}
                    venue_values   = location_field ? location_field.pvalues("VVENUE") : nil
                    venue_uid      = venue_values ? venue_values.first : venue_values
                    venue_uid ? content_venues.find{|content_venue| content_venue.match(/^UID:#{venue_uid}$/m)} : nil
                  rescue Exception => e
                    # Ignore
                    RAILS_DEFAULT_LOGGER.info("SourceParser::Ical.to_abstract_events : Failed to parse content_venue for non-Upcoming event -- #{e}")
                    nil
                  end
                end
              end

            event.location = to_abstract_location(content_venue, :fallback => component.location)
           events << event
          end
        end
      end
    end

    # Return an AbstractLocation extracted from an iCalendar input.
    #
    # Arguments:
    # * value - String with iCalendar data to parse which contains a Vvenue item.
    #
    # Options:
    # * :fallback - String to use as the title for the location if the +value+ doesn't contain a Vvenue.
    def self.to_abstract_location(value, opts={})
      value = "" if value.nil?
      a = AbstractLocation.new

      # The Vpim libary doesn't understand that Vvenue entries are just Vcards,
      # so transform the content to trick it into treating them as such.
      if vcard_content = value.scan(VENUE_CONTENT_RE).first
        vcard_content.gsub!(VENUE_CONTENT_BEGIN_RE, 'BEGIN:VCARD')
        vcard_content.gsub!(VENUE_CONTENT_END_RE,   'END:VCARD')

        begin
          vcards = Vpim::Vcard.decode(vcard_content)
          raise ArgumentError, "Wrong number of vcards" unless vcards.size == 1
          vcard = vcards.first

          a.title          = vcard['name']
          a.street_address = vcard['address']
          a.locality       = vcard['city']
          a.region         = vcard['region']
          a.postal_code    = vcard['postalcode']
          a.country        = vcard['country']

          a.latitude, a.longitude = vcard['geo'].split(/;/).map(&:to_f)

          return a
        rescue Vpim::InvalidEncodingError, ArgumentError, RuntimeError
          # Exceptional state will be handled below
          :ignore # Leave this line in for rcov's code coverage
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

