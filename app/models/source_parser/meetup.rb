class SourceParser # :nodoc:
  class Meetup < Base
    label :Meetup
    url_pattern %r{^http://(?:www\.)?meetup\.com/([^/]+)/events/([^/]+)/?}

    def self.to_abstract_events(opts={})
      if SECRETS.meetup_api_key.present?
        matchdata = opts[:url].match(url_pattern)
        event_id = matchdata[2]
        return false unless event_id # Give up unless we can extract the id

        meetup_data = HTTParty.get("https://api.meetup.com/2/event/#{event_id}",
            :query => { :key => SECRETS.meetup_api_key, :sign => 'true' })

        event = AbstractEvent.new
        event.title       = meetup_data['name']
        event.description = meetup_data['description']
        # Meetup sends us milliseconds since the epoch in UTC
        event.start_time  = Time.at(meetup_data['time']/1000).utc
        event.url         = meetup_data['event_url']
        event.location    = to_abstract_location(meetup_data['venue'])
        event.tags        = ["meetup:event=#{event_id}", "meetup:group=#{meetup_data['group']['urlname']}"]

        [event]
      else
        self.to_abstract_events_wrapper(
          opts,
          SourceParser::Ical,
          url_pattern,
          lambda { |matcher| "http://www.meetup.com/#{matcher[1]}/events/#{matcher[2]}/ical/omgkittens.ics" }
        )
      end
    end

    def self.to_abstract_location(value, opts={})
      if value.present?
        location = AbstractLocation.new
        location.title   = value['name']
        location.street_address = [value['address_1'], value['address_2'], value['address_3']].compact.join(", ")
        location.locality = value['city']
        location.region = value['state']
        location.postal_code = value['zip']
        location.country = value['country']
        location.telephone = value['phone']
        location.tags = ["meetup:venue=#{value['id']}"]
      else
        location = nil
      end

      return location
    end
  end
end
