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
    
    # Helper to set the start and end dates correctly depending on whether it's a floating or fixed timezone
    def self.dates_for_tz(component, event)
      if component.dtstart_property.tzid.nil?
        event.start_time  = Time.parse(component.dtstart_property.value)
        if component.dtend_property.nil?
          if component.duration
            event.end_time = component.duration_property.add_to_date_time_value(event.start_time)
          else
            event.end_time = event.start_time
          end
        else
          event.end_time = Time.parse(component.dtend_property.value)
        end
      else
        event.start_time  = component.dtstart
        event.end_time    = component.dtend
      end
    rescue RiCal::InvalidTimezoneIdentifier
      event.start_time = Time.parse(component.dtstart_property.to_s)
      event.end_time = Time.parse(component.dtend_property.to_s)
    end

    CALENDAR_CONTENT_RE    = /^BEGIN:VCALENDAR.*?^END:VCALENDAR/m
    EVENT_CONTENT_RE       = /^BEGIN:VEVENT.*?^END:VEVENT/m
    EVENT_DTSTART_RE       = /^DTSTART.*?:([^\r\n$]+)/m
    EVENT_DTEND_RE         = /^DTEND.*?:([^\r\n$]+)/m
    VENUE_CONTENT_RE       = /^BEGIN:VVENUE$.*?^END:VVENUE$/m
    VENUE_CONTENT_BEGIN_RE = /^BEGIN:VVENUE$/m
    VENUE_CONTENT_END_RE   = /^END:VVENUE$/m
    IS_UPCOMING_RE         = /^PRODID:\W+Upcoming/m

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

      # Provide special handling for Upcoming's broken implementation of iCalendar
      if content.match(IS_UPCOMING_RE)
        # Strip out superflous self-referential Upcoming link
        content.sub!(%r{\s*\[\s*Full details at http://upcoming.yahoo.com/event/\d+/?\s*\]\s*}m, '')

        # Fix newlines in DESCRIPTION, replace them with escaped '\n' strings.
        matches = content.scan(/^(DESCRIPTION:.+?)(?:^\w+[:;])/m)
        matches.each do |match|
          content.sub!(match[0], match[0].strip.gsub(/\n/, '\n')+"\r\n")
        end
      end

      events = []
      content_calendars = RiCal.parse_string(content)
      content_calendars.each do |content_calendar|
        content_calendar.events.each_with_index do |component, index|
          next if opts[:skip_old] && (component.dtend || component.dtstart).to_time < cutoff
          event             = AbstractEvent.new
          event.title       = component.summary
          event.description = component.description
          event.url         = component.url

          SourceParser::Ical.dates_for_tz(component, event)

          content_venues = content_calendar.to_s.scan(VENUE_CONTENT_RE)

          content_venue = \
          begin
            if content_calendar.to_s.match(%r{VALUE=URI:http://upcoming.yahoo.com/})
              # Special handling for Upcoming, where each event maps 1:1 to a venue
              content_venues[index]
            else
              begin                
                # finding the event venue id - VVENUE=V0-001-001423875-1@eventful.com
                venue_uid = component.location_property.params["VVENUE"]
                # finding in the content_venues array an item matching the uid
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
      value = "" if value.nil?
      a = AbstractLocation.new


      # Vvenue entries are considered just Vcards,
      # treating them as such.
      if vcard_content = value.scan(VENUE_CONTENT_RE).first

        begin
          vcards = RiCal.parse_string(vcard_content)
          raise ArgumentError, "Wrong number of vcards" unless vcards.size == 1
          vcard = vcards.first
          # this is an interesting call here
          # RiCal export of nonstandard-outside-of-RFC2445
          # VVENUE into lines
          vcard_lines = vcard.export_properties_to(STDOUT)
          vcard_hash = vcard_lines.mash do |line|
            # predeclare key, value in case no match
            key = ''
            value = ''
            # if line is of the form key:value
            # where the line has at least one colon
            # do a non-greedy capture of chars not colon
            # followed by a promiscuous match of remaining chars 
            if line.match(/^([^:]+?):(.*)$/)
              key = $1
              value = $2
              # if the key has a semi-colon, it is, by spec, 
              # followed by a meta-qualifier;  
              # in all cases, we only want the key and not the qualifier
              # split always at least returns one item
              # which will always be the item we want
              # we only want the first: drop the second on match semi-colon
              key = key.split(';').first
            end
            [key, value]
          end

          a.title          = vcard_hash['NAME']
          a.street_address = vcard_hash['ADDRESS']
          a.locality       = vcard_hash['CITY']
          a.region         = vcard_hash['REGION']
          a.postal_code    = vcard_hash['POSTALCODE']
          a.country        = vcard_hash['COUNTRY']

          a.latitude, a.longitude = vcard_hash['GEO'].split(/;/).map(&:to_f)

          return a
        # we should be able to remove the Vpim exceptions?
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

