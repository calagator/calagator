module Calagator

class Source::Parser::Facebook < Source::Parser
  self.label = :Facebook

  # NOTE: This pattern's goal is to get the Facebook event identifier in the
  # first capture group, so the "(?:foo)" non-capturing group syntax is used
  # to match but not capture those groups -- 
  # search the web for "ruby class rexep non-capturing" for details.
  self.url_pattern = %r{(?x)              # Ignore regexp whitespace and comments
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

  def to_events
    return unless data = to_events_api_helper(url) do |event_id|
      raise Calagator::Source::Parser::HttpAuthenticationRequiredError unless Calagator.facebook_access_token.present?
      [
        "https://graph.facebook.com/#{event_id}",
        { access_token: Calagator.facebook_access_token }
      ]
    end

    raise Calagator::Source::Parser::HttpAuthenticationRequiredError if data['parsed_response'] === false

    event = Event.new({
      source:      source,
      title:       data['name'],
      description: data['description'],
      url:         url,
      tag_list:    "facebook:event=#{data['id']}",
      venue:       to_venue(data),

      # Facebook is sending floating times, treat them as local
      start_time:  Time.zone.parse(data['start_time']),
      end_time:    Time.zone.parse(data['end_time']),
    })

    [event_or_duplicate(event)]
  end

  private

  def to_venue(data)
    fields = (data['venue'] || {})
    return if fields.blank?

    venue = Venue.new({
      source:         source,
      title:          data['location'],
      street_address: fields['street'],
      locality:       fields['city'],
      region:         fields['state'],
      country:        fields['country'],
      latitude:       fields['latitude'],
      longitude:      fields['longitude'],
    })
    venue.geocode!
    venue_or_duplicate(venue)
  end
end

end
