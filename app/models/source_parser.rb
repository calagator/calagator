# == SourceParser
#
# A hierarchy of classes that provide a way to parse different source formats and return hCalendar events.
class SourceParser
  # Return an Array of AbstractEvent instances.
  #
  # Options: (these vary between specific parsers)
  # * :url - URL string to read as parser input.
  # * :content - String to read as parser input.
  def self.to_abstract_events(opts)
    matched_parser = parsers.find{|parser|
      parser.url_pattern.present? && opts[:url].try(:match, parser.url_pattern)
    }

    # Cache the content
    content = self.content_for(opts)

    # Return events from the first parser that suceeds, starting with the parser
    # that matches the given URL if one is found.
    parsers.unshift(matched_parser).compact.uniq.each do |parser|
      begin
        events = parser.to_abstract_events(opts.merge(:content => content))
        return events if not events.blank?
      rescue Exception => e
        # Ignore
      end
    end

    # Return empty set if no matches
    return []
  end

  # Returns an Array of parser classes for the various formats
  def self.parsers
    $SourceParserImplementations.compact
  end

  # Return content for the arguments
  def self.content_for(*args)
    ::SourceParser::Base.content_for(*args).to_s.strip
  end

  # Return content for a URL
  def self.read_url(*args)
    ::SourceParser::Base.read_url(*args)
  end

  # == SourceParser::Base
  #
  # The base class for all format-specific parsers. Do not use this class
  # directly, use a subclass of Base to do the parsing instead.
  class Base
    def self.inherited(subclass)
      # Add class-wide ::_label accessor to subclasses.
      subclass.meta_eval {attr_accessor :_label}
      subclass.meta_eval {attr_accessor :_url_pattern}

      $SourceParserImplementations << subclass unless $SourceParserImplementations.include?(subclass)
    end

    # Gets or sets the human-readable label for this parser.
    def self.label(value=nil)
      self._label = value if value
      return self._label
    end

    # Gets or sets the applicable URL pattern for this parser.
    def self.url_pattern(value=nil)
      self._url_pattern = value if value
      return self._url_pattern
    end

    # Returns content from either the :content option or by reading a :url.
    def self.content_for(opts)
      content = opts[:content] || self.read_url(opts[:url])
      if content.respond_to?(:content_type) && ["application/atom+xml"].include?(content.content_type)
        return CGI::unescapeHTML(content)
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

    # Wrapper for invoking a driver from another, e.g. if given a Plancast URL,
    # fetch another URL and parse it with the iCalendar driver.
    #
    # Arguments:
    # * opts: Hash with <tt>to_abstract_events</tt> options.
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

# Load format-specific drivers in the following order:
$SourceParserImplementations = []
SourceParser::Plancast
SourceParser::Meetup
SourceParser::Upcoming
SourceParser::Facebook
SourceParser::Ical
SourceParser::Hcal
