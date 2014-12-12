class Source::Parser
  HTMLEntitiesCoder = HTMLEntities.new

  # == Source::Parser::Hcal
  #
  # Reads hCalendar events.
  class Hcal < Source::Parser::Base
    label :hCalendar

    EVENT_TO_HCALENDAR_FIELD_MAP = {
      :title => :summary,
      :description => true,
      :start_time => :dtstart,
      :end_time => :dtend,
      :url => true,
      :venue => :location,
    }

    # Returns a set of Event objects.
    #
    # Options:
    # * :url => URL String to read events from.
    def self.to_events(opts = {})
      new(opts).to_events
    end

    def to_events
      hcals = to_hcals
      
      hcals.map do |hcal|
        event = Event.new.tap do |event|
          event.source = opts[:source]
          EVENT_TO_HCALENDAR_FIELD_MAP.each do |field, mofo_field|
            mofo_field = field if mofo_field == true
            next unless hcal.respond_to?(mofo_field)
            raw_field = hcal.send(mofo_field)
            next unless raw_field
            decoded_field = \
              case mofo_field
              when :dtstart
                HTMLEntitiesCoder.decode(raw_field)
              #when :dtend
              #  HTMLEntitiesCoder.decode(raw_field)
              when :location
                to_venue(opts.merge(:value => raw_field))
              else
                raw_field
              end
            event.send("#{field}=", decoded_field)
          end
        end
        event_or_duplicate(event)
      end.uniq do |event|
        [event.attributes, event.venue.try(:attributes)]
      end
    end

    VENUE_TO_HCARD_FIELD_MAP = {
      :title => :fn,
      :telephone => :tel,
      :email => true,
      :description => :note,
    }

    # Return a Venue.
    #
    # Options:
    # * :value -- hCard or string location
    def to_venue(opts)
      venue = Venue.new.tap do |venue|
        venue.source = opts[:source]
        raw = opts[:value]

        case raw
        when String
          venue.title = raw
        when HCard
          VENUE_TO_HCARD_FIELD_MAP.each do |field, mofo_field|
            mofo_field = field if mofo_field == true
            venue[field] = raw.send(mofo_field).try(:strip_html) if raw.respond_to?(mofo_field)
          end

          if raw.respond_to?(:geo)
            %w(latitude longitude).each do |field|
              venue[field] = raw.geo.send(field) if raw.geo.respond_to?(field)
            end
          end

          if raw.respond_to?(:adr)
            %w(street_address locality region country_name postal_code).each do |field|
              case field
              when 'country_name'
                venue[:country] = raw.adr.send(field) if raw.adr.respond_to?(field)
              when 'postal_code'
                venue[:postal_code] = raw.adr.send(field).to_s if raw.adr.respond_to?(field)
              else
                venue[field] = raw.adr.send(field) if raw.adr.respond_to?(field)
              end
            end
          end

          # FIXME: should attempt to fill in fields based on whatever input is available, such as hcard org
        else
          raise ArgumentError, "Unknown location type in hCalendar: #{raw.class}"
        end
        venue.geocode!
      end
      venue_or_duplicate(venue)
    end

    private

    def to_hcals
      content = self.class.read_url(opts[:url])
      something = hCalendar.find(:text => content)
      something.is_a?(hCalendar) ? [something] : something
    end
  end
end
