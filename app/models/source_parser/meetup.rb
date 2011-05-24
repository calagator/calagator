class SourceParser # :nodoc:
  class Meetup < Base
    def self.to_abstract_events(opts={})
      self.to_abstract_events_wrapper(
        opts,
        SourceParser::Ical,
        %r{^http://(?:www\.)?meetup\.com/([^/]+)/events/([^/]+)/?},
        lambda { |matcher| "http://www.meetup.com/#{matcher[1]}/events/#{matcher[2]}/ical/omgkittens.ics" }
      )
    end
  end
end
