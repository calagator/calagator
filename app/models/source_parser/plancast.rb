class SourceParser # :nodoc:
  class Plancast < Base
    label :Plancast
    url_pattern %r{^http://(?:www\.)?plancast\.com/p/([^/]+)/?}

    def self.to_events(opts={})
      self.to_events_api_helper(
        :url => opts[:url],
        :api => lambda { |event_id|
          [
            'http://api.plancast.com/02/plans/show.json',
            {
              :query => {
                :plan_id => event_id,
                :extensions => 'place'
              }
            }
          ]
        }
      ) do |data, event_id|
        event = Event.new
        event.source      = opts[:source]
        event.title       = data['what']
        event.description = data['description']

        # Plancast is sending floating times as Unix timestamps, which is hard to parse
        event.start_time  = ActiveSupport::TimeWithZone.new(nil, Time.zone, Time.at(data['start'].to_i).utc)
        event.end_time    = ActiveSupport::TimeWithZone.new(nil, Time.zone, Time.at(data['stop'].to_i).utc)

        event.url         = (data['external_url'] || data['plan_url'])
        event.tag_list    = "plancast:plan=#{event_id}"

        event.venue       = to_venue(data['place'], opts.merge(:fallback => data['where']))

        [event_or_duplicate(event)]
      end
    end

    def self.to_venue(value, opts={})
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
      elsif opts[:fallback].present?
        venue = Venue.new(title: opts[:fallback])
        venue_or_duplicate(venue)
      end
    end
  end
end
