class Event < ActiveRecord::Base
  class IcalRenderer
    
    attr_reader :events, :opts

    def initialize(events, opts)
      @events = Array(events)
      @opts = opts
    end

    def render
      icalendar = RiCal.Calendar do |calendar|
        calendar.prodid = "-//Calagator//EN"

        events.each do |item|
          calendar.event do |entry|
            add_event(item, entry)
          end
        end
      end

      # Add the calendar name, normalize line-endings to UNIX LF, then replace them with DOS CF-LF.
      icalendar.
        export.
        sub(/(CALSCALE:\w+)/i, "\\1\nX-WR-CALNAME:#{SETTINGS.name}\nMETHOD:PUBLISH").
        gsub(/\r\n/,"\n").
        gsub(/\n/,"\r\n")
    end

    private

    def add_event(item, entry)
      entry.summary(item.title || 'Untitled Event')
      
      desc = build_description(item)
      entry.description(desc) unless desc.blank?

      set_start_end(item, entry)

      set_url(item, entry)

      set_location(item, entry)

      entry.created       item.created_at if item.created_at
      entry.last_modified item.updated_at if item.updated_at

      # Set the iCalendar SEQUENCE, which should be increased each time an
      # event is updated. If an admin needs to forcefully increment the
      # SEQUENCE for all events, they can edit the "config/secrets.yml"
      # file and set the "icalendar_sequence_offset" value to something
      # greater than 0.
      entry.sequence((SECRETS.icalendar_sequence_offset || 0) + item.versions.count)

      # dtstamp and uid added because of a bug in Outlook;
      # Outlook 2003 will not import an .ics file unless it has DTSTAMP, UID, and METHOD
      # use created_at for DTSTAMP; if there's no created_at, use event.start_time;
      entry.dtstamp item.created_at || item.start_time
      entry.uid     "#{opts[:url_helper].call(item)}" if opts[:url_helper]
    end

    def build_description(item)
      desc = ""
      if item.multiday?
        desc << "This event runs from #{TimeRange.new(item.start_time, item.end_time, :format => :text).to_s}."
        desc << "\n\n Description:\n"
      end

      desc << Loofah::Helpers::strip_tags(item.description) if item.description.present?
      desc << "\n\nTags: #{item.tag_list}" unless item.tag_list.blank?
      desc << "\n\nImported from: #{opts[:url_helper].call(item)}" if opts[:url_helper]
      desc
    end

    def set_start_end(item, entry)
      if item.multiday?
        entry.dtstart item.dates.first
        entry.dtend   item.dates.last + 1.day
      else
        entry.dtstart item.start_time
        entry.dtend   item.end_time || item.start_time + 1.hour
      end
    end

    def set_url(item, entry)
      if item.url.present?
        entry.url item.url
      end
    end

    def set_location(item, entry)
      if item.venue
        entry.location [item.venue_title, item.venue.full_address].compact.join(": ")
      end
    end

  end
end