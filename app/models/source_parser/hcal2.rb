class SourceParser # :nodoc:
  class Hcal2 < Base
    label :Hcal2

    def self.to_abstract_events(opts={})
      data = ::Microformats2.parse(opts[:content])
      event_data = data[:hevent]
      return false unless event_data.present?

      events = []
      for item in event_data
        event             = AbstractEvent.new
        event.title       = item.try(:summary)
        event.description = item.try(:description)
        event.start_time  = item.try(:dtstart)
        event.end_time    = item.try(:dtend)
        event.url         = item.try(:url)
        location          = AbstractLocation.new
        location.title    = item.try(:location)
        event.location    = location
        events << event
      end

      events
    end
    
    # TODO: implement full venue extraction once the spec/parsing is clearer
  end
end
