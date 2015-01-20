require "net/http"
require "net/https"
require "open-uri"

# == Source::Parser
#
# A hierarchy of classes that provide a way to parse different source formats and return hCalendar events.
# The base class for all format-specific parsers. Do not use instances of this class
# directly, use a subclass of Parser to do the parsing instead.
class Source::Parser < Struct.new(:opts)
  # Return an Array of unsaved Event instances.
  #
  # Options: (these vary between specific parsers)
  # * :url - URL string to read as parser input.
  # * :content - String to read as parser input.
  def self.to_events(opts)
    # Return events from the first parser that suceeds
    events = matched_parsers(opts[:url]).lazy.collect { |parser|
      parser.new(opts).to_events
    }.detect(&:present?)

    events || []
  end

  def self.matched_parsers(url)
    # start with the parser that matches the given URL
    parsers.sort_by do |parser|
      match = parser.url_pattern.present? && url.try(:match, parser.url_pattern)
      match ? 0 : 1
    end
  end
  private_class_method :matched_parsers

  cattr_accessor(:parsers) { SortedSet.new }

  def self.inherited(subclass)
    parsers << subclass
  end

  class_attribute :label, :url_pattern

  # Returns an Array of sorted string labels for the parsers.
  def self.labels
    parsers.map { |p| p.label.to_s }.sort_by(&:downcase)
  end

  def self.read_url(url)
    RestClient.get(url).to_str
  rescue RestClient::Unauthorized
    raise Source::Parser::HttpAuthenticationRequiredError.new
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

    # Get URL and params for using the API.
    url, params = *block.call(event_id)

    # Get data from the API.
    data = RestClient.get(url, params: params, accept: "json").to_str
    data = JSON.parse(data)

    # Stop if API tells us there's an error.
    raise Source::Parser::NotFound, error if error = data[error_key]

    data['event_id'] = event_id
    data
  end
end

require 'source/parser/not_found'
require 'source/parser/plancast'
require 'source/parser/meetup'
require 'source/parser/facebook'
require 'source/parser/ical'
require 'source/parser/hcal'

