require 'source_parser/not_found'

# == SourceParser
#
# A hierarchy of classes that provide a way to parse different source formats and return hCalendar events.
class SourceParser
  # Return an Array of AbstractEvent instances.
  #
  # Options: (these vary between specific parsers)
  # * :url - URL string to read as parser input.
  # * :content - String to read as parser input.
  def self.to_events(opts)
    opts[:content] = content_for(opts)
    source = opts.delete(:source)

    # start with the parser that matches the given URL
    matched_parsers = parsers.sort_by do |parser|
      match = parser.url_pattern.present? && opts[:url].try(:match, parser.url_pattern)
      match ? 0 : 1
    end

    # Return events from the first parser that suceeds
    events = matched_parsers.each do |parser|
      events = parser.to_abstract_events(opts)
      break events.uniq if events.present?
    end

    events ||= []

    events.map do |abstract_event|
      event = Event.new

      event.source       = source
      event.title        = abstract_event.title
      event.description  = abstract_event.description
      event.start_time   = abstract_event.start_time.blank? ? nil : Time.parse(abstract_event.start_time.to_s)
      event.end_time     = abstract_event.end_time.blank? ? nil : Time.parse(abstract_event.end_time.to_s)
      event.url          = abstract_event.url
      event.tag_list     = abstract_event.tags.join(',')

      if abstract_location = abstract_event.location
        venue = Venue.new

        venue.source = source
        abstract_location.each_pair do |key, value|
          next if key == :tags
          venue[key] = value unless value.blank?
        end
        venue.tag_list = abstract_location.tags.join(',')

        # We must add geocoding information so this venue can be compared to existing ones.
        venue.geocode!

        # if the new venue has no exact duplicate, use the new venue
        # otherwise, find the ultimate master and return it
        duplicates = venue.find_exact_duplicates

        if duplicates.present?
          venue = duplicates.first.progenitor
        else
          venue_machine_tag_name = abstract_location.tags.find { |t|
            # Match 2 in the MACHINE_TAG_PATTERN is the predicate
            ActsAsTaggableOn::Tag::VENUE_PREDICATES.include? t.match(ActsAsTaggableOn::Tag::MACHINE_TAG_PATTERN)[2]
          }
          matched_venue = Venue.tagged_with(venue_machine_tag_name).first

          venue = matched_venue.progenitor if matched_venue.present?
        end

        event.venue = venue
      end

      duplicates = event.find_exact_duplicates
      event = duplicates.first.progenitor if duplicates
      event
    end
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
