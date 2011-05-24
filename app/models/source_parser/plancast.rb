class SourceParser # :nodoc:
  class Plancast < Base
    def self.to_abstract_events(opts={})
      self.to_abstract_events_wrapper(
        opts,
        SourceParser::Ical, 
        %r{^http://(?:www\.)?plancast\.com/p/([^/]+)/?},
        lambda { |matcher| "http://plancast.com/p/#{matcher[1]}?feed=ical" }
      )
    end
  end
end
