class SourceParser # :nodoc:
  class Plancast < Base
    def self.to_abstract_events(opts={})
      expression = %r{^http://(?:www\.)?plancast\.com/p/([^/]+)/?}
      abstract_events = self.to_abstract_events_wrapper(
        opts,
        SourceParser::Ical, 
        expression,
        lambda { |matcher| "http://plancast.com/p/#{matcher[1]}?feed=ical" }
      )
      matchdata = opts[:url].match(expression)
      tag = "plancast:plan=#{matchdata[1]}"
      abstract_events.each { |e| e.tags << tag }

      abstract_events
    end
  end
end
