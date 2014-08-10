class Event < ActiveRecord::Base
  class IcalRenderer
    def self.render(events, opts)
      icalendar = build(events, opts)

      # Add the calendar name, normalize line-endings to UNIX LF, then replace them with DOS CF-LF.
      icalendar.
        export.
        sub(/(CALSCALE:\w+)/i, "\\1\nX-WR-CALNAME:#{SETTINGS.name}\nMETHOD:PUBLISH").
        gsub(/\r\n/,"\n").
        gsub(/\n/,"\r\n")
    end

    def self.build(events, opts)
      icalendar = RiCal.Calendar do |calendar|
        calendar.prodid = "-//Calagator//EN"

        Array(events).each do |item|
          calendar.event do |entry|
            renderer = new(item, entry, opts)
            renderer.add_event
          end
        end
      end
    end

    attr_reader :item, :entry, :imported_from

    def initialize(item, entry, opts)
      @item = item
      @entry = entry
      @imported_from = opts[:url_helper].call(item).to_s if opts[:url_helper]
    end

    def add_event
      entry.summary item.title || 'Untitled Event'

      entry.description description unless description.blank?
      entry.url item.url if item.url.present?
      entry.location location if location
      entry.dtstart start_time
      entry.dtend end_time

      entry.created       item.created_at if item.created_at
      entry.last_modified item.updated_at if item.updated_at

      # Set the iCalendar SEQUENCE, which should be increased each time an
      # event is updated. If an admin needs to forcefully increment the
      # SEQUENCE for all events, they can edit the "config/secrets.yml"
      # file and set the "icalendar_sequence_offset" value to something
      # greater than 0.
      entry.sequence (SECRETS.icalendar_sequence_offset || 0) + item.versions.count

      # dtstamp and uid added because of a bug in Outlook;
      # Outlook 2003 will not import an .ics file unless it has DTSTAMP, UID, and METHOD
      # use created_at for DTSTAMP; if there's no created_at, use event.start_time;
      entry.dtstamp item.created_at || item.start_time
      entry.uid imported_from if imported_from
    end

    private

    def description
      return @desc if defined?(@desc) # memoize

      desc = ""
      if item.multiday?
        time_range = TimeRange.new(item.start_time, item.end_time, format: :text)
        desc << "This event runs from #{time_range}.\n\n Description:\n"
      end

      desc << Loofah::Helpers.strip_tags(item.description) if item.description.present?
      desc << "\n\nTags: #{item.tag_list}" unless item.tag_list.blank?
      desc << "\n\nImported from: #{imported_from}" if imported_from

      @desc = desc
    end

    def location
      [item.venue_title, item.venue.full_address].compact.join(": ") if item.venue
    end

    def start_time
      if item.multiday?
        item.dates.first
      else
        item.start_time 
      end
    end

    def end_time
      if item.multiday?
        item.dates.last + 1.day 
      else
        item.end_time || item.start_time + 1.hour
      end
    end
  end
end
