class Source < ActiveRecord::Base
  class Importer
    def initialize params
      @source = Source.find_or_create_from(params)
    end

    def source
      @source
    end

    def valid?
      @valid ||= @source.valid?
    end

    def events
      if valid?
        begin
          return @events = @source.create_events!
        rescue SourceParser::NotFound => e
          @source.errors.add(:base, "No events found at remote site. Is the event identifier in the URL correct?")
        rescue SourceParser::HttpAuthenticationRequiredError => e
          @source.errors.add(:base, "Couldn't import events, remote site requires authentication.")
        rescue OpenURI::HTTPError => e
          @source.errors.add(:base, "Couldn't download events, remote site may be experiencing connectivity problems. ")
        rescue Errno::EHOSTUNREACH => e
          @source.errors.add(:base, "Couldn't connect to remote site.")
        rescue SocketError => e
          @source.errors.add(:base, "Couldn't find IP address for remote site. Is the URL correct?")
        rescue Exception => e
          @source.errors.add(:base, "Unknown error: #{e}")
        end
        nil
      end
    end
  end
end

