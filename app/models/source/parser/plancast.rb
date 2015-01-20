class Source::Parser::Plancast < Source::Parser
  self.label = :Plancast
  self.url_pattern = %r{^http://(?:www\.)?plancast\.com/p/([^/]+)/?}

  def to_events
    return unless data = get_data
    event = Event.new({
      source:      opts[:source],
      title:       data['what'],
      description: data['description'],

      # Plancast is sending floating times as Unix timestamps, which is hard to parse
      start_time:  ActiveSupport::TimeWithZone.new(nil, Time.zone, Time.at(data['start'].to_i).utc),
      end_time:    ActiveSupport::TimeWithZone.new(nil, Time.zone, Time.at(data['stop'].to_i).utc),

      url:         (data['external_url'] || data['plan_url']),
      tag_list:    "plancast:plan=#{data['event_id']}",

      venue:       to_venue(data['place'], data['where']),
    })

    [event_or_duplicate(event)]
  end

  private

  def get_data
    to_events_api_helper(opts[:url]) do |event_id|
      [
        'http://api.plancast.com/02/plans/show.json',
        {
          plan_id: event_id,
          extensions: 'place'
        }
      ]
    end
  end

  def to_venue(value, fallback=nil)
    value = "" if value.nil?
    if value.present?
      venue = Venue.new({
        source: opts[:source],
        title: value['name'],
        address: value['address'],
        tag_list: "plancast:place=#{value['id']}",
      })
      venue.geocode!
      venue_or_duplicate(venue)
    elsif fallback.present?
      venue = Venue.new(title: fallback)
      venue_or_duplicate(venue)
    end
  end
end
