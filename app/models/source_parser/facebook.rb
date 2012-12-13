class SourceParser # :nodoc:
  class Facebook < Base
    label :Facebook
    # NOTE: This pattern's goal is to get the Facebook event identifier in the first capture group, so the "(?:foo)" non-capturing group syntax is used to match but not capture those groups -- search the web for "ruby class rexep non-capturing" for details.
    #
    url_pattern %r{(?x)                     # Ignore regexp whitespace and comments
      ^
        (?:https?://)?                      # Optional http URI prefix
        (?:
          (?:www\.)?                        # Optional 'www.' host prefix
          (?:
            facebook\.com/events/           # REST-style path
          |                                 # ...or....
            facebook\.com/event\.php\?eid=  # GET-style path
          )
        |                                   # ...or...
          graph\.facebook\.com/             # API path
        )
        ([^/]+)                             # Facebook event identifier to capture
      }

    def self.to_abstract_events(opts={})
      self.to_abstract_events_api_helper(
        :url => opts[:url],
        :api => lambda { |event_id|
          "http://graph.facebook.com/#{event_id}"
        }
      ) do |data, event_id|
        raise ::SourceParser::HttpAuthenticationRequiredError if data['parsed_response'] === false

        event = AbstractEvent.new
        event.title       = data['name']
        event.description = data['description']

        # Facebook is sending floating times, treat them as local
        event.start_time  = Time.zone.parse(data['start_time'])
        event.end_time    = Time.zone.parse(data['end_time'])
        event.url         = opts[:url]
        event.tags        = ["facebook:event=#{data['id']}"]

        # The 'venue' block in facebook's data doesn't contain the venue name, so we merge…
        data = (data['venue'] || {}).merge('name' => data['location'])
        event.location    = to_abstract_location(data)

        [event]
      end
    end

    def self.to_abstract_location(value, opts={})
      value ||= {}
      if value.present?
        location = AbstractLocation.new
        location.title   = value['name']
        location.street_address = value['street']
        location.locality = value['city']
        location.region = value['state']
        location.country = value['country']
        location.latitude = value['latitude']
        location.longitude = value['longitude']
      else
        location = nil
      end

      return location
    end
  end
end

