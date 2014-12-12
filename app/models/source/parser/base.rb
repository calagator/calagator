require "net/http"
require "net/https"
require "open-uri"

class Source::Parser
  # == Source::Parser::Base
  #
  # The base class for all format-specific parsers. Do not use this class
  # directly, use a subclass of Base to do the parsing instead.
  class Base < Struct.new(:opts)
    cattr_accessor(:parsers) { SortedSet.new }

    def self.inherited(subclass)
      parsers << subclass
    end

    class_attribute :label, :url_pattern

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
          response = http.request(request)
          raise Source::Parser::HttpAuthenticationRequiredError.new if response.code == "401"
          response.body
        else
          uri.read
        end
      else
        open(url) { |h| h.read }
      end
    end

    def self.to_events(opts={})
      new(opts).to_events
    end

    def to_events
      raise NotImplementedError
    end

    def self.<=>(other)
      # use site-specific parsers first, then generics alphabetically
      if self.url_pattern && !other.url_pattern
        -1
      elsif !self.url_pattern && other.url_pattern
        1
      else
        self.label <=> other.label
      end
    end

    private

    def event_or_duplicate(event)
      duplicates = event.find_exact_duplicates
      if duplicates.present?
        duplicates.first.progenitor
      else
        event
      end
    end

    def venue_or_duplicate(venue)
      duplicates = venue.find_exact_duplicates
      if duplicates.present?
        duplicates.first.progenitor
      else
        venue_machine_tag_name = venue.tag_list.find { |t|
          # Match 2 in the MACHINE_TAG_PATTERN is the predicate
          ActsAsTaggableOn::Tag::VENUE_PREDICATES.include? t.match(ActsAsTaggableOn::Tag::MACHINE_TAG_PATTERN)[2]
        }
        matched_venue = Venue.tagged_with(venue_machine_tag_name).first

        if matched_venue.present?
          matched_venue.progenitor
        else
          venue
        end
      end
    end

    def to_events_api_helper(url, error_key="error", &block)
      # Extract +event_id+ from :url using +url_pattern+.
      event_id = url[self.class.url_pattern, 1]
      return false unless event_id # Give up unless we find the identifier.

      # Get URL and arguments for using the API.
      api_args = block.call(event_id)

      # Get data from the API.
      data = HTTParty.get(*api_args)

      # Stop if API tells us there's an error.
      raise Source::Parser::NotFound, error if error = data[error_key]

      data['event_id'] = event_id
      data
    end
  end
end
