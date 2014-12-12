class Source::Parser # :nodoc:
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

    def self.to_events(opts={})
      new(opts).to_events
    end

    def to_events
      to_events_api_helper(
        :url => opts[:url],
        :api => lambda { |event_id|
          "http://graph.facebook.com/#{event_id}"
        }
      ) do |data, event_id|
        raise ::Source::Parser::HttpAuthenticationRequiredError if data['parsed_response'] === false

        event = Event.new
        event.source      = opts[:source]
        event.title       = data['name']
        event.description = data['description']

        # Facebook is sending floating times, treat them as local
        event.start_time  = Time.zone.parse(data['start_time'])
        event.end_time    = Time.zone.parse(data['end_time'])
        event.url         = opts[:url]
        event.tag_list    = "facebook:event=#{data['id']}"

        # The 'venue' block in facebook's data doesn't contain the venue name, so we merge…
        data = (data['venue'] || {}).merge('name' => data['location'])
        event.venue       = to_venue(data)

        [event_or_duplicate(event)]
      end
    end

    def to_venue(value)
      return if value.blank?
      venue = Venue.new({
        source: opts[:source],
        title: value['name'],
        street_address: value['street'],
        locality: value['city'],
        region: value['state'],
        country: value['country'],
        latitude: value['latitude'],
        longitude: value['longitude'],
      })
      venue.geocode!
      venue_or_duplicate(venue)
    end
  end
end

