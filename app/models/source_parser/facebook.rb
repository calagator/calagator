class SourceParser # :nodoc:
  class Facebook < Base
    label :Facebook
    url_pattern %r{^http://(?:www\.)?facebook\.com/event.php\?eid=([^/]+)/?}

    def self.to_abstract_events(opts={})
      matchdata = opts[:url].match(url_pattern)
      event_id = matchdata[1]
      return false unless event_id # Give up unless we can extract the Facebook event_id

      # Make an api call to the Facebook graph API to get event data.
      facebook_data = HTTParty.get("http://graph.facebook.com/#{event_id}")

      raise ::SourceParser::HttpAuthenticationRequiredError if facebook_data.parsed_response === false

      event = AbstractEvent.new
      event.title       = facebook_data['name']
      event.description = facebook_data['description']
      # Facebook is sending floating times, treat them as local
      event.start_time  = Time.zone.parse(facebook_data['start_time'])
      event.end_time    = Time.zone.parse(facebook_data['end_time'])
      event.url         = opts[:url]
      event.tags        = ["facebook:event=#{facebook_data['id']}"]

      # The 'venue' block in facebook's data doesn't contain the venue name, so we merge…
      venue_data = (facebook_data['venue'] || {}).merge('name' => facebook_data['location'])
      event.location    = to_abstract_location(venue_data)

      [event]
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

