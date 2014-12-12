class Source::Parser # :nodoc:
  class Meetup < Base
    label :Meetup
    url_pattern %r{^http://(?:www\.)?meetup\.com/[^/]+/events/([^/]+)/?}

    def self.to_events(opts={})
      new(opts).to_events
    end

    def to_events
      if SECRETS.meetup_api_key.present?
        to_events_api_helper(
          :url => opts[:url],
          :error => 'problem',
          :api => lambda { |event_id|
            [
              "https://api.meetup.com/2/event/#{event_id}",
              {
                :query => {
                  :key => SECRETS.meetup_api_key,
                  :sign => 'true'
                }
              }
            ]
          }
        ) do |data, event_id|
          event = Event.new
          event.source      = opts[:source]
          event.title       = data['name']
          event.description = data['description']
          # Meetup sends us milliseconds since the epoch in UTC
          event.start_time  = Time.at(data['time']/1000).utc
          event.url         = data['event_url']
          event.venue       = to_venue(data['venue'])
          event.tag_list    = "meetup:event=#{event_id}, meetup:group=#{data['group']['urlname']}"

          [event_or_duplicate(event)]
        end
      else
        self.class.to_events_wrapper(
          opts,
          Source::Parser::Ical,
          %r{^http://(?:www\.)?meetup\.com/([^/]+)/events/([^/]+)/?},
          lambda { |matcher| "http://www.meetup.com/#{matcher[1]}/events/#{matcher[2]}/ical" }
        )
      end
    end

    def to_venue(value)
      return if value.blank?
      venue = Venue.new({
        source: opts[:source],
        title: value['name'],
        street_address: [value['address_1'], value['address_2'], value['address_3']].compact.join(", "),
        locality: value['city'],
        region: value['state'],
        postal_code: value['zip'],
        country: value['country'],
        telephone: value['phone'],
        tag_list: "meetup:venue=#{value['id']}",
      })
      venue.geocode!
      venue_or_duplicate(venue)
    end
  end
end
