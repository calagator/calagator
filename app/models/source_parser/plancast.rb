class SourceParser # :nodoc:
  class Plancast < Base
    label :Plancast
    url_pattern %r{^http://(?:www\.)?plancast\.com/p/([^/]+)/?}

    def self.to_abstract_events(opts={})
      self.to_abstract_events_api_helper(
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
        event = AbstractEvent.new
        event.title       = data['what']
        event.description = data['description']

        # Plancast is sending floating times as Unix timestamps, which is hard to parse
        event.start_time  = ActiveSupport::TimeWithZone.new(nil, Time.zone, Time.at(data['start'].to_i).utc)
        event.end_time    = ActiveSupport::TimeWithZone.new(nil, Time.zone, Time.at(data['stop'].to_i).utc)

        event.url         = (data['external_url'] || data['plan_url'])
        event.tags        = ["plancast:plan=#{event_id}"]

        event.location    = to_abstract_location(data['place'], :fallback => data['where'])

        [event]
      end
    end

    def self.to_abstract_location(value, opts={})
      value = "" if value.nil?
      if value.present?
        location = AbstractLocation.new
        location.title   = value['name']
        location.address = value['address']
        location.tags = ["plancast:place=#{value['id']}"]
      elsif opts[:fallback].blank?
        location = nil
      else
        location = AbstractLocation.new(:title => opts[:fallback])
      end

      return location
    end
  end
end
