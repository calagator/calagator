module Calagator

class Source::Parser::Meetup < Source::Parser
  self.label = :Meetup
  self.url_pattern = %r{^https?://(?:www\.)?meetup\.com/[^/]+/events/([^/]+)/?}

  def to_events
    return fallback unless Calagator.meetup_api_key.present?
    return unless data = get_data
    start_time = Time.at(data['time']/1000).utc
    event = Event.new({
      source:      source,
      title:       "#{data['group']['name']} - #{data['name']}",
      description: data['description'],
      url:         data['event_url'],
      venue:       to_venue(data['venue']),
      tag_list:    "meetup:event=#{data['event_id']}, meetup:group=#{data['group']['urlname']}#{group_topics(data)}",
      # Meetup sends us milliseconds since the epoch in UTC
      start_time:  start_time,
      end_time: data['duration'] ? start_time + data['duration']/1000 : nil
    })

    [event_or_duplicate(event)]
  end

  private

  def fallback
    to_events_wrapper(
      Source::Parser::Ical,
      %r{^http://(?:www\.)?meetup\.com/([^/]+)/events/([^/]+)/?},
      lambda { |matcher| "http://www.meetup.com/#{matcher[1]}/events/#{matcher[2]}/ical" }
    )
  end

  def get_data
    to_events_api_helper(url, "problem") do |event_id|
      [
        "https://api.meetup.com/2/event/#{event_id}",
        {
          key: Calagator.meetup_api_key,
          sign: 'true',
          fields: 'topics'
        }
      ]
    end
  end

  def group_topics(data)
    topics = data['group']['topics']
    topics.map{ |t| t['name'].downcase }.join(', ').insert(0, ', ') unless topics.empty?
  end

  def to_venue(value)
    return if value.blank?
    venue = Venue.new({
      source: source,
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

  def to_events_wrapper(driver, match, template)
    url.try(:match, match) do |matcher|
      url = template.call(matcher)
      driver.new(url, source).to_events
    end
  end
end

end
