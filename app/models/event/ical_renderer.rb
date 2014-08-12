class Event < ActiveRecord::Base
  class IcalRenderer
    def self.render(events, opts)
      icalendar = build_icalendar(events, opts)

      output = icalendar.export

      # add the calendar name
      output.sub!(/(CALSCALE:\w+)/i, "\\1\nX-WR-CALNAME:#{SETTINGS.name}\nMETHOD:PUBLISH")

      # normalize line-endings to DOS CF-LF.
      output.gsub!(/\r?\n/,"\r\n")
    end

    def self.build_icalendar(events, opts)
      RiCal.Calendar do |calendar|
        calendar.prodid = "-//Calagator//EN"

        Array(events).each do |event|
          calendar.event do |entry|
            new(event, entry, opts).add_event
          end
        end
      end
    end

    attr_reader :event, :entry, :imported_from

    def initialize(event, entry, opts)
      @event = event
      @entry = entry
      @imported_from = opts[:url_helper].call(event).to_s if opts[:url_helper]
    end

    def add_event
      entry.summary event.title || 'Untitled Event'

      entry.description description unless description.blank?
      entry.url event.url if event.url.present?
      entry.location location if location
      entry.dtstart start_time
      entry.dtend end_time

      entry.created       event.created_at if event.created_at
      entry.last_modified event.updated_at if event.updated_at

      # Set the iCalendar SEQUENCE, which should be increased each time an
      # event is updated. If an admin needs to forcefully increment the
      # SEQUENCE for all events, they can edit the "config/secrets.yml"
      # file and set the "icalendar_sequence_offset" value to something
      # greater than 0.
      entry.sequence (SECRETS.icalendar_sequence_offset || 0) + event.versions.count

      # dtstamp and uid added because of a bug in Outlook;
      # Outlook 2003 will not import an .ics file unless it has DTSTAMP, UID, and METHOD
      # use created_at for DTSTAMP; if there's no created_at, use event.start_time;
      entry.dtstamp event.created_at || event.start_time
      entry.uid imported_from if imported_from
    end

    private

    def description
      return @desc if defined?(@desc) # memoize

      desc = ""
      if event.multiday?
        time_range = TimeRange.new(event.start_time, event.end_time, format: :text)
        desc << "This event runs from #{time_range}.\n\n Description:\n"
      end

      desc << Loofah::Helpers.strip_tags(event.description) if event.description.present?
      desc << "\n\nTags: #{event.tag_list}" unless event.tag_list.blank?
      desc << "\n\nImported from: #{imported_from}" if imported_from

      @desc = desc
    end

    def location
      [event.venue_title, event.venue.full_address].compact.join(": ") if event.venue
    end

    def start_time
      if event.multiday?
        event.dates.first
      else
        event.start_time
      end
    end

    def end_time
      if event.multiday?
        event.dates.last + 1.day
      else
        event.end_time || event.start_time + 1.hour
      end
    end
  end
end