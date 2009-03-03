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
    # Upcoming consistently breaks their hCalendar content and I can't keep fixing the parser. The following horrible hack rewrites Upcoming's hCalendar URLs into iCalendar URLs in hopes that they're paying more attention to iCalendar's validity and so that we've only got one single set of Upcoming parser hacks. Here's what the two types of URLs look like:
    # hCalendar: http://upcoming.yahoo.com/event/1366250/
    # iCalendar: webcal://upcoming.yahoo.com/calendar/v2/event/1366250
    if matcher = opts[:url].ergo.match(%r{http://upcoming.yahoo.com/event/(\w+)})
      opts[:url] = "http://upcoming.yahoo.com/calendar/v2/event/#{matcher[1]}"
    end

    content = self.content_for(opts)

    returning([]) do |events|
      parsers.each do |parser|
        begin
          events.concat(parser.to_abstract_events(opts.merge(:content => content)))
        rescue Exception => e
          RAILS_DEFAULT_LOGGER.info("SourceParser.to_abstract_events : Can't parse with #{parser.name} because -- #{e}")
          :ignore # Leave this line for rcov's code coverage
        end
      end
    end
  end

  # Returns an Array of parser classes for the various formats
  def self.parsers
    $SourceParserImplementations.map{|parser| parser}.uniq
  end

  # Return content for the arguments
  def self.content_for(*args)
    ::SourceParser::Base.content_for(*args)
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

      # Use global because it's the only data structure that survives a Rails #reload!
      $SourceParserImplementations ||= Set.new
      $SourceParserImplementations << subclass
    end

    # Gets or sets the human-readable label for this parser.
    def self.label(value=nil)
      self._label = value if value
      return self._label
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
    def self.to_abstract_events(opts={})
      raise NotImplementedError, "Do not use #{self.class}.to_abstract_events method directly"
    end
  end
end

# Load all the format-specific drivers in the "source_parser" directory
source_parser_driver_path = File.join(File.dirname(__FILE__), "source_parser")
for entry in Dir.entries(source_parser_driver_path).select{|t| t.match(/.+\.rb$/)}
  require File.join(source_parser_driver_path, entry)
end
