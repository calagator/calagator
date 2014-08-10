class SourceParser
  HTMLEntitiesCoder = HTMLEntities.new

  # == SourceParser::Hcal
  #
  # Reads hCalendar events.
  class Hcal < SourceParser::Base
    label :hCalendar

    # Returns a set of hCalendar events.
    #
    # Options:
    # * :url => URL String to read events from.
    # * :content => String of data to read events from 
    def self.to_hcals(opts={})
      content = content_for(opts)

      # Workarounds for Upcoming:
      # v2 invalid HTML
      content.gsub!(/(class="venue location vcard" )class="vcard"/, '\1')
      # v3 invalid hCalendar description
      content.gsub!(%r{(<div class="description">)(</div>)(.+?)(<div class="clearb">)}m, '\1\3\2\4')
      
      unless content.match(/ class="description"/)
        # v4 hCalendar description no longer contained in its own div
        content.gsub!(/<!-- \/.venue -->(.*?)<div id="small-info">/m, %q{
<!-- \/.venue -->
<div class="description">\1</div>
<div id="small-info">
                    })
      end
      # ... and there is an extra 'vevent' class
      content.gsub!(/(class="event-title") class="vevent"/, '\1')

      something = hCalendar.find(:text => content)
      something.is_a?(hCalendar) ? [something] : something
    end

    ABSTRACT_EVENT_TO_HCALENDAR_FIELD_MAP = {
      :title => :summary,
      :description => true,
      :start_time => :dtstart,
      :end_time => :dtend,
      :url => true,
      :location => true
    }

    # Returns a set of AbstractEvent objects.
    #
    # Options:
    # * :url => URL String to read events from.
    def self.to_abstract_events(opts = {})
      hcals = to_hcals(opts)
      
      hcals.map do |hcal|
        AbstractEvent.new.tap do |event|
          ABSTRACT_EVENT_TO_HCALENDAR_FIELD_MAP.each do |abstract_field, mofo_field|
            mofo_field = abstract_field if mofo_field == true
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
                to_abstract_location(:value => raw_field)
              else
                raw_field
              end
            event.send("#{abstract_field}=", decoded_field)
          end
        end
      end
    end

    ABSTRACT_LOCATION_TO_HCARD_FIELD_MAP = {
      :title => :fn,
      :telephone => :tel,
      :email => true,
      :description => :note,
    }

    # Return an AbstractLocation.
    #
    # Options:
    # * :value -- hCard or string location
    def self.to_abstract_location(opts)
      AbstractLocation.new.tap do |a|
        raw = opts[:value]

        case raw
        when String
          a.title = raw
        when HCard
          ABSTRACT_LOCATION_TO_HCARD_FIELD_MAP.each do |abstract_field, mofo_field|
            mofo_field = abstract_field if mofo_field == true
            a[abstract_field] = raw.send(mofo_field).try(:strip_html) if raw.respond_to?(mofo_field)
          end

          if raw.respond_to?(:geo)
            %w(latitude longitude).each do |field|
              a[field] = raw.geo.send(field) if raw.geo.respond_to?(field)
            end
          end

          if raw.respond_to?(:adr)
            %w(street_address locality region country_name postal_code).each do |field|
              case field
              when 'country_name'
                a[:country] = raw.adr.send(field) if raw.adr.respond_to?(field)
              when 'postal_code'
                a[:postal_code] = raw.adr.send(field).to_s if raw.adr.respond_to?(field)
              else
                a[field] = raw.adr.send(field) if raw.adr.respond_to?(field)
              end
            end
          end

          # FIXME: should attempt to fill in fields based on whatever input is available, such as hcard org
        else
          raise ArgumentError, "Unknown location type in hCalendar: #{raw.class}"
        end
      end
    end

  end
end
