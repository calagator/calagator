require "net/http"
require "net/https"
require "open-uri"

$SourceParserImplementations = []

class SourceParser
  # == SourceParser::Base
  #
  # The base class for all format-specific parsers. Do not use this class
  # directly, use a subclass of Base to do the parsing instead.
  class Base
    def self.inherited(subclass)
      $SourceParserImplementations << subclass unless $SourceParserImplementations.include?(subclass)
    end

    class_attribute :_label, :_url_pattern

    # Gets or sets the human-readable label for this parser.
    def self.label(value=nil)
      self._label = value if value
      return self._label
    end

    # Gets or sets the applicable URL pattern for this parser.
    #
    # This pattern must have the event identifier as the first capture group.
    #
    # Example:
    #   # The pattern below gets the event id as the first capture group:
    #   url_pattern %r{^https?://facebook\.com/events/([^/]+)}
    def self.url_pattern(value=nil)
      self._url_pattern = value if value
      return self._url_pattern
    end

    # Returns content from either the :content option or by reading a :url.
    def self.content_for(opts)
      content = opts[:content] || self.read_url(opts[:url])
      if content.respond_to?(:content_type) && ["application/atom+xml"].include?(content.content_type)
        return CGI::unescapeHTML(content.to_str)
      else
        return content
      end
    end

    # Returns content read from a URL. Easier to stub.
    def self.read_url(url)
      uri = URI.parse(url)
      if uri.respond_to?(:read)
        if ['http', 'https'].include?(uri.scheme)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = (uri.scheme == 'https')
          path_and_query = uri.path.blank? ? "/" : uri.path
          path_and_query += "?#{uri.query}" if uri.query
          request = Net::HTTP::Get.new(path_and_query)
          request.basic_auth(uri.user, uri.password)
          response = SourceParser::Base::http_response_for(http, request)
          if response.code == "401"
            raise SourceParser::HttpAuthenticationRequiredError.new
          end
          return response.body
        else
          return uri.read
        end
      else
        return open(url){|h| h.read}
      end
    end

    # Return the HTTPResponse for the +http+ connection and the +request+.
    def self.http_response_for(http, request)
      return http.request(request)
    end

    # Stub which makes sure that subclasses of Base implement the #parse method.
    def self.to_hcals(opts={})
      raise NotImplementedError, "Do not use #{self.class}.to_hcals method directly"
    end

    # Stub which makes sure that subclasses of Base implement the #parse method.
    #
    # Options:
    # * :url -- URL of iCalendar data to import
    # * :content -- String of iCalendar data to import
    def self.to_abstract_events(opts={})
      raise NotImplementedError, "Do not use #{self.class}.to_abstract_events method directly"
    end

    # Wrapper for getting abstract events from a JSON API.
    #
    # @example See SourceParser::Facebook for an example of this in use.
    #
    # @option opts [String] :url the user-provided URL for the event page.
    # @option opts [String] :error the name of the JSON field that indicates an error, defaults to +error+.
    # @option opts [Proc] :api a lambda that gets the +event_id+ and
    #   returns the arguments to send to +HTTParty.get+ for downloading
    #   data. This is usually a URL string and an optional hash of query
    #   parameters.
    # @yield a block for processing the downloaded JSON data.
    # @yieldparam [Hash] data the JSON data downloaded from the API.
    # @yieldparam [String] event_id the event's identifier.
    # @yieldreturn [Array<AbstractEvent>] events.
    # @return [Array<AbstractEvent>] events.
    def self.to_abstract_events_api_helper(opts, &block)
      return false unless opts[:url]
      raise ArgumentError, "No block specified" unless block
      raise ArgumentError, "No API specified" unless opts[:api]

      # Extract +event_id+ from :url using +url_pattern+.
      event_id = opts[:url][self.url_pattern, 1]
      return false unless event_id # Give up unless we find the identifier.

      # Get URL and arguments for using the API.
      api_args = opts[:api].call(event_id)

      # Get data from the API.
      data = HTTParty.get(*api_args)

      # Stop if API tells us there's an error.
      opts[:error] ||= 'error'
      if error = data[opts[:error]]
        raise SourceParser::NotFound, error
      end

      # Process the JSON data into AbstractEvents.
      return yield(data, event_id)
    end

    # Wrapper for invoking a driver from another, e.g. if given a Plancast URL,
    # fetch another URL and parse it with the iCalendar driver.
    #
    # Arguments:
    # * opts: Hash with +to_abstract_events+ options.
    # * driver: Driver that should parse the results. Should be a subclass of SourceParser::Base.
    # * source: Regular expression for extracting the event id from the URL.
    # * target: Lambda for generating the URL that the +driver+ should parse. It's called with a Regexp matcher for the +source+ and emits a string URL that the +driver+ should parse.
    #
    # Example:
    #
    #   class SourceParser
    #     class Plancast < Base
    #       label :Plancast
    #       def self.to_abstract_events(opts={})
    #         # Invoke the wrapper
    #         self.to_abstract_events_wrapper(
    #           # Pass along the opts
    #           opts,
    #           # Parse using the Ical driver
    #           SourceParser::Ical,
    #           # Regexp describing how to extract an event identifier from the
    #           # URL. So if given "http://plancast.com/p/5ivg", the event
    #           # identifier will be "5ivg".
    #           %r{^http://(?:www\.)?plancast\.com/p/([^/]+)/?},
    #           # Lambda that generates a string URL based on the match above
    #           lambda { |matcher| "http://plancast.com/p/#{matcher[1]}?feed=ical" }
    #         )
    #       end
    #     end
    #   end
    def self.to_abstract_events_wrapper(opts, driver, source, target)
      if matcher = opts[:url].match(source)
        driver.to_abstract_events(opts.merge(
          :content => self.read_url(target.call(matcher)
        )))
      else
        return nil
      end
    end
  end
end
