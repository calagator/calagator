require 'source/parser/not_found'
require 'source/parser/plancast'
require 'source/parser/meetup'
require 'source/parser/facebook'
require 'source/parser/ical'
require 'source/parser/hcal'

# == Source::Parser
#
# A hierarchy of classes that provide a way to parse different source formats and return hCalendar events.
class Source::Parser
  # Return an Array of unsaved Event instances.
  #
  # Options: (these vary between specific parsers)
  # * :url - URL string to read as parser input.
  # * :content - String to read as parser input.
  def self.to_events(opts)
    # start with the parser that matches the given URL
    matched_parsers = parsers.sort_by do |parser|
      match = parser.url_pattern.present? && opts[:url].try(:match, parser.url_pattern)
      match ? 0 : 1
    end

    # Return events from the first parser that suceeds
    events = matched_parsers.lazy.collect { |parser|
      parser.to_events(opts)
    }.detect(&:present?)

    events || []
  end

  # Returns an Array of parser classes for the various formats
  def self.parsers
    ::Source::Parser::Base.parsers
  end

  # Returns an Array of sorted string labels for the parsers.
  def self.labels
    self.parsers.map(&:label).map(&:to_s).sort_by(&:downcase)
  end

  # Return content for a URL
  def self.read_url(*args)
    ::Source::Parser::Base.read_url(*args)
  end
end

