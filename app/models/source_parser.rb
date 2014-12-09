require 'source_parser/not_found'

# == SourceParser
#
# A hierarchy of classes that provide a way to parse different source formats and return hCalendar events.
class SourceParser
  # Return an Array of unsaved Event instances.
  #
  # Options: (these vary between specific parsers)
  # * :url - URL string to read as parser input.
  # * :content - String to read as parser input.
  def self.to_events(opts)
    opts[:content] = content_for(opts)

    # start with the parser that matches the given URL
    matched_parsers = parsers.sort_by do |parser|
      match = parser.url_pattern.present? && opts[:url].try(:match, parser.url_pattern)
      match ? 0 : 1
    end

    # Return events from the first parser that suceeds
    events = matched_parsers.each do |parser|
      events = parser.to_events(opts)
      break events if events.present?
    end

    events || []
  end

  # Returns an Array of parser classes for the various formats
  def self.parsers
    $SourceParserImplementations.compact
  end

  # Returns an Array of sorted string labels for the parsers.
  def self.labels
    self.parsers.map(&:label).map(&:to_s).sort_by(&:downcase)
  end

  # Return content for the arguments
  def self.content_for(*args)
    ::SourceParser::Base.content_for(*args).to_s.strip
  end

  # Return content for a URL
  def self.read_url(*args)
    ::SourceParser::Base.read_url(*args)
  end
end

# Load format-specific drivers in the following order:
SourceParser::Plancast
SourceParser::Meetup
SourceParser::Facebook
SourceParser::Ical
SourceParser::Hcal
