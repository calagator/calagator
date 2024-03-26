# frozen_string_literal: true

module Calagator
  module GoogleEventExportHelper
    # Return a Google Calendar export URL.

    def google_event_export_link(event)
      GoogleEventExportLink.new(event, self).render
    end

    class GoogleEventExportLink < Struct.new(:event, :context)
      def render
        truncate(url + query)
      end

      private

      def url
        "https://www.google.com/calendar/event?action=TEMPLATE&trp=true&"
      end

      def query
        fields.collect do |field|
          send(field).to_query(field)
        end.compact.join("&")
      end

      def fields
        %i[text dates location sprop details]
      end

      def text
        event.title
      end

      def dates
        google_time_format = "%Y%m%dT%H%M%SZ"
        end_time = event.end_time || event.start_time
        "#{event.start_time.utc.strftime(google_time_format)}/#{end_time.utc.strftime(google_time_format)}"
      end

      def location
        location = event.venue.try(:title)
        if (address = event.venue.try(:geocode_address))
          location += ", #{address}" if address.present?
        end
        location
      end

      def sprop
        "website:#{event.url.sub(%r{^http.?://}, "")}" if event.url.present?
      end

      def details
        "Imported from: #{context.event_url(event)} \n\n#{event.description}"
      end

      def truncate(string)
        omission = "...[truncated]"
        length = 1024 - omission.length
        context.truncate(string, length: length, omission: omission)
      end
    end
  end
end
