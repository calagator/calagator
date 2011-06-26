class SourceParser # :nodoc:
  class Plancast < Base
    label :Plancast

    def self.to_abstract_events(opts={})

      expression = %r{^http://(?:www\.)?plancast\.com/p/([^/]+)/?}
      matchdata = opts[:url].match(expression)
      plan_id = matchdata[1]
      return false unless plan_id # Give up unless we can extract the Plancast plan_id

      # Make an api call to http://api.plancast.com/02/plans/show.json?plan_id=IDXX&extensions=place
      plancast_data = HTTParty.get('http://api.plancast.com/02/plans/show.json',
          :query => { :plan_id => plan_id, :extensions => 'place' })

      event = AbstractEvent.new
      event.title       = plancast_data['what']
      event.description = plancast_data['description']
      # Plancast is sending floating times as Unix timestamps, which is hard to parse
      event.start_time  = ActiveSupport::TimeWithZone.new(nil, Time.zone, Time.at(plancast_data['start'].to_i).utc)
      event.end_time    = ActiveSupport::TimeWithZone.new(nil, Time.zone, Time.at(plancast_data['stop'].to_i).utc)
      event.url         = (plancast_data['external_url'] || plancast_data['plan_url'])
      event.location    = to_abstract_location(plancast_data['place'], :fallback => plancast_data['where'])
      event.tags        = ["plancast:plan=#{plan_id}"]

      [event]
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
