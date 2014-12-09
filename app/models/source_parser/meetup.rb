class SourceParser # :nodoc:
  class Meetup < Base
    label :Meetup
    url_pattern %r{^http://(?:www\.)?meetup\.com/[^/]+/events/([^/]+)/?}

    def self.to_events(opts={})
      if SECRETS.meetup_api_key.present?
        self.to_events_api_helper(
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
        self.to_events_wrapper(
          opts,
          SourceParser::Ical,
          %r{^http://(?:www\.)?meetup\.com/([^/]+)/events/([^/]+)/?},
          lambda { |matcher| "http://www.meetup.com/#{matcher[1]}/events/#{matcher[2]}/ical/omgkittens.ics" }
        )
      end
    end

    def self.to_venue(value, opts={})
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
