# Return an iCalendar string representing an Array of Event instances.
#
# Arguments:
# * :events - Event instance or array of them.
#
# Options:
# * :url_helper - Lambda that accepts an Event instance and generates a URL
#   for it if it doesn't have a URL already.
#
# Example:
#   ics1 = Event::IcalRenderer.render(myevent)
#   ics2 = Event::IcalRenderer.render(myevents, url_helper: -> (event) { event_url(event) })
class Event < ActiveRecord::Base
  class IcalRenderer
    def self.render(events, opts={})
      output = render_icalendar(events, opts)
      output = add_name(output)
      output = normalize_line_endings(output)
    end

    def self.render_icalendar(events, opts)
      RiCal.Calendar do |calendar|
        calendar.prodid = "-//Calagator//EN"

        Array(events).each do |event|
          calendar.event do |entry|
            new(event, opts).add_event_to(entry)
          end
        end
      end.export
    end

    def self.add_name(output)
      output.sub(/(CALSCALE:\w+)/i, "\\1\nX-WR-CALNAME:#{SETTINGS.name}\nMETHOD:PUBLISH")
    end

    def self.normalize_line_endings(output)
      output.gsub(/\r?\n/,"\r\n")
    end

    attr_reader :event, :imported_from

    def initialize(event, opts)
      @event = event
      @imported_from = opts[:url_helper].call(event).to_s if opts[:url_helper]
    end

    def add_event_to(entry)
      fields.each do |field|
        value = send(field)              # value = summary
        entry.send field, value if value # entry.summary summary if summary
      end
    end

    private

    def fields
      %w(summary description url location dtstart dtend created last_modified sequence dtstamp uid)
    end

    def summary
      event.title || 'Untitled Event'
    end

    def description
      parts = [
        description_range,
        description_description,
        description_tags,
        description_imported_from,
      ].compact

      parts.join if parts.any?
    end

    def description_range
      return unless multiday?
      time_range = TimeRangeHelper.normalize_time(event, format: :text)
      "This event runs from #{time_range}.\n\nDescription:\n"
    end

    def description_description
      Loofah::Helpers.strip_tags(event.description) if event.description.present?
    end

    def description_tags
      "\n\nTags: #{event.tag_list}" if event.tag_list.present?
    end

    def description_imported_from
      "\n\nImported from: #{imported_from}" if imported_from
    end

    def url
      event.url if event.url.present?
    end

    def location
      [event.venue_title, event.venue.full_address].compact.join(": ") if event.venue
    end

    def dtstart
      if multiday?
        event.dates.first
      else
        event.start_time
      end
    end

    def dtend
      if multiday?
        event.dates.last + 1.day
      else
        event.end_time || event.start_time + 1.hour
      end
    end

    def created
      event.created_at if event.created_at
    end

    def last_modified
      event.updated_at if event.updated_at
    end

    def sequence
      # Set the iCalendar SEQUENCE, which should be increased each time an
      # event is updated. If an admin needs to forcefully increment the
      # SEQUENCE for all events, they can edit the "config/secrets.yml"
      # file and set the "icalendar_sequence_offset" value to something
      # greater than 0.
      (SECRETS.icalendar_sequence_offset || 0) + event.versions.count
    end

    def dtstamp
      # dtstamp and uid added because of a bug in Outlook;
      # Outlook 2003 will not import an .ics file unless it has DTSTAMP, UID, and METHOD
      # use created_at for DTSTAMP; if there's no created_at, use event.start_time;
      event.created_at || event.start_time
    end

    def uid
      imported_from
    end

    # Treat any event with a duration of at least 20 hours as a multiday event.
    def multiday?
      event.dates.size > 1 && event.duration.seconds > 20.hours
    end
  end
end
