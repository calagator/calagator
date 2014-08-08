class Source < ActiveRecord::Base
  class Importer < Struct.new(:source)
    def initialize params
      self.source = Source.find_or_create_from(params)
    end

    def events
      defined?(@events) ? @events : @events = begin
        return unless source.valid?
        begin
          return source.create_events!
        rescue SourceParser::NotFound
          source.errors.add :base, "No events found at remote site. Is the event identifier in the URL correct?"
        rescue SourceParser::HttpAuthenticationRequiredError
          source.errors.add :base, "Couldn't import events, remote site requires authentication."
        rescue OpenURI::HTTPError
          source.errors.add :base, "Couldn't download events, remote site may be experiencing connectivity problems."
        rescue Errno::EHOSTUNREACH
          source.errors.add :base, "Couldn't connect to remote site."
        rescue SocketError
          source.errors.add :base, "Couldn't find IP address for remote site. Is the URL correct?"
        rescue Exception => e
          source.errors.add :base, "Unknown error: #{e}"
        end
        nil
      end
    end

    def events?
      events.try(:any?)
    end

    def failure_message
      if events.nil?
        "Unable to import: #{source.errors.full_messages.to_sentence}"
      else
        "Unable to find any upcoming events to import from this source"
      end
    end
  end
end

