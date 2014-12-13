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
class Source::Parser::Ical < Source::Parser
    self.label = :iCalendar

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

    def to_events
      # Skip old events by default

      opts[:skip_old] = true unless opts[:skip_old] == false
      cutoff = Time.now.yesterday

      content = self.class.read_url(opts[:url]).gsub(/\r\n/, "\n")
      content = munge_gmt_dates(content)

      return [].tap do |events|
        begin
          content_calendars = RiCal.parse_string(content)
        rescue Exception => e
          if e.message =~ /Invalid icalendar file/
            return false # Invalid data, give up.
          else
            raise e # Unknown error, we should care.
          end
        end
        content_calendars.each do |content_calendar|
          content_calendar.events.each_with_index do |component, index|
            next if opts[:skip_old] && (component.dtend || component.dtstart).to_time < cutoff
            event             = Event.new
            event.source      = opts[:source]
            event.title       = component.summary
            event.description = component.description
            event.url         = component.url

            dates_for_tz(component, event)

            content_venues = content_calendar.to_s.scan(VENUE_CONTENT_RE)

            content_venue = \
            begin
              # finding the event venue id - VVENUE=V0-001-001423875-1@eventful.com
              venue_uid = component.location_property.params["VVENUE"]
              # finding in the content_venues array an item matching the uid
              venue_uid ? content_venues.find{|content_venue| content_venue.match(/^UID:#{venue_uid}$/m)} : nil
            rescue Exception => e
              # Ignore
              Rails.logger.info("Source::Parser::Ical.to_events : Failed to parse content_venue for event -- #{e}")
              nil
            end

            event.venue = to_venue(content_venue, opts.merge(:fallback => component.location))
            events << event_or_duplicate(event)
          end
        end
        events.uniq do |event|
          [event.attributes, event.venue.try(:attributes)]
        end
      end
    end

    private

    # Helper to set the start and end dates correctly depending on whether it's a floating or fixed timezone
    def dates_for_tz(component, event)
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

    def munge_gmt_dates(content)
      content.gsub(/;TZID=GMT:(.*)/, ':\1Z')
    end

    # Return an Venue extracted from an iCalendar input.
    #
    # Arguments:
    # * value - String with iCalendar data to parse which contains a VVENUE item.
    #
    # Options:
    # * :fallback - String to use as the title for the location if the +value+ doesn't contain a VVENUE.
    def to_venue(value, opts={})
      value = "" if value.nil?
      venue = Venue.new

      # VVENUE entries are considered just Vcards,
      # treating them as such.
      if vcard_content = value.scan(VENUE_CONTENT_RE).first
        vcard_hash = hash_from_vcard_string(vcard_content)

        venue.title          = vcard_hash['NAME']
        venue.street_address = vcard_hash['ADDRESS']
        venue.locality       = vcard_hash['CITY']
        venue.region         = vcard_hash['REGION']
        venue.postal_code    = vcard_hash['POSTALCODE']
        venue.country        = vcard_hash['COUNTRY']

        venue.latitude, venue.longitude = vcard_hash['GEO'].split(/;/).map(&:to_f)

      elsif opts[:fallback].present?
        venue.title = opts[:fallback]
      else
        return nil
      end

      venue.geocode!
      venue_or_duplicate(venue)
    end

    # Return hash parsed from the contents of first VCARD found in the iCalendar data.
    #
    # Properties with meta-qualifiers are treated specially. When a property with a meta-qualifier is parsed (e.g. "FOO;BAR"), it will also set a value for the key (e.g. "FOO") if one isn't specified. This makes it possible to retrieve a value for a key like "DTSTART" when only a key with a qualifier like "DTSTART;TZID=..." is specified in the data.
    #
    # Arguments:
    # * data - String of iCalendar data containing a VCARD.
    def hash_from_vcard_string(data)
      # Only use first vcard of a VVENUE
      vcard = RiCal.parse_string(data).first

      # Extract all properties, including non-standard ones, into an array of "KEY;meta-qualifier:value" strings
      vcard_lines = vcard.export_properties_to(StringIO.new(''))

      hash_from_vcard_lines(vcard_lines)
    end

    # Return hash parsed from VCARD lines.
    #
    # Arguments:
    # * vcard_lines - Array of "KEY;meta-qualifier:value" strings.
    def hash_from_vcard_lines(vcard_lines)
      {}.tap do |vcard_hash|
        # Turn a String-like object into an Enumerable.
        lines = vcard_lines.respond_to?(:lines) ? vcard_lines.lines : vcard_lines
        lines.each do |vcard_line|
          if matcher = vcard_line.match(/^([^;]+?)(;[^:]*?)?:(.*)$/)
            key = matcher[1]
            qualifier = matcher[2]
            value = matcher[3]

            if qualifier
              # Add entry for a key and its meta-qualifier
              vcard_hash["#{key}#{qualifier}"] = value

              # Add fallback entry for a key from the matching meta-qualifier, e.g. create key "foo" from contents of key with meta-qualifier "foo;bar".
              unless vcard_hash.has_key?(key)
                vcard_hash[key] = value
              end
            else
              # Add entry for a key without a meta-qualifier.
              vcard_hash[key] = value
            end
          end
        end
      end
    end
end
