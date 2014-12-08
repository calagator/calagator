# == Schema Information
# Schema version: 20110604174521
#
# Table name: sources
#
#  id          :integer         not null, primary key
#  title       :string(255)
#  url         :string(255)
#  imported_at :datetime
#  created_at  :datetime
#  updated_at  :datetime
#  reimport    :boolean
#

# == Source
#
# A model that represents a source of events data, such as feeds for hCal, iCal, etc.
class Source < ActiveRecord::Base
  validate :assert_url

  has_many :events,  :dependent => :destroy
  has_many :venues,  :dependent => :destroy
  has_many :updates, :dependent => :destroy

  scope :listing, -> { order('created_at DESC') }

  has_paper_trail

  xss_foliate
  include DecodeHtmlEntitiesHack

  # Return a newly-created or existing Source record matching the given
  # attributes. The +attrs+ hash is the same format as used when calling
  # Source::new.
  #
  # This method is intended to supplement the import process by providing a
  # single Source record for each unique URL, thus when multiple people import
  # the same URL, there will only be one Source record.
  #
  # The :reimport flag is given special handling: If the original Source record
  # has this set to true, it will never be set back to false by this method.
  # The intent behind this is that if one person wants this Source reimported,
  # the reimporting shouldn't be disabled by someone else manually importing it
  # without setting the reimport flag. If someone really wants to turn off
  # reimporting, they should edit the source.
  def self.find_or_create_from(attrs={})
    if attrs && attrs[:url]
      source = Source.find_or_create_by_url(attrs[:url])
      attrs.each_pair do |key, value|
        if key.to_sym == :reimport
          source.reimport = true if ! source.reimport && value
        else
          source.send("#{key}=", value) if source.send(key) != value
        end
      end
      source.save if source.changed?
      return source
    else
      return Source.new(attrs)
    end
  end

  # Create events for this source. Returns the events created. URL must be set
  # for this source for this to work.
  def create_events!(opts={})
    cutoff = Time.now.yesterday # All events before this date will be skipped
    events = []
    self.to_events(opts).each do |event|
      if opts[:skip_old]
        next if event.title.blank? && event.description.blank? && event.url.blank?
        next if event.old?
      end

      # Skip invalid events that start after they end
      next if event.end_time && event.end_time < event.start_time

      # convert to local time, because time zone is simply discarded when event is saved
      event.start_time.localtime
      event.end_time.localtime if event.end_time

      # clear duplicate_of_id field in case to_events picked up orphaned duplicate
      # TODO clear the duplicate_of_id at the point where the object is created, not down here
      event.duplicate_of_id = nil if event.duplicate_of_id
      event.save!
      if event.venue
        event.venue.duplicate_of_id = nil if event.venue.duplicate_of_id
        event.venue.save! if event.venue
      end
      events << event
    end
    self.save!
    return events
  end

  # Normalize the URL.
  def url=(value)
    begin
      url = URI.parse(value.strip)
      url.scheme = 'http' unless ['http','https','ftp'].include?(url.scheme) || url.scheme.nil?
      write_attribute(:url, url.scheme.nil? ? 'http://'+value.strip : url.to_s)
    rescue URI::InvalidURIError
      false
    end
  end

  # Returns an Array of Event objects that were read from this source.
  #
  # Options:
  # * :url -- URL of data to import. Defaults to record's #url attribute.
  # * :skip_old -- Should old events be skipped? Default is true.
  def to_events(opts={})
    raise ActiveRecord::RecordInvalid, self unless valid?

    self.imported_at = Time.now
    opts[:url] ||= self.url
    SourceParser.to_abstract_events(opts).uniq.map do |abstract_event|
      event = Event.new

      event.source       = self
      event.title        = abstract_event.title
      event.description  = abstract_event.description
      event.start_time   = abstract_event.start_time.blank? ? nil : Time.parse(abstract_event.start_time.to_s)
      event.end_time     = abstract_event.end_time.blank? ? nil : Time.parse(abstract_event.end_time.to_s)
      event.url          = abstract_event.url
      event.tag_list     = abstract_event.tags.join(',')

      if abstract_location  = abstract_event.location
        venue = Venue.new

        venue.source = self
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

        event.venue        = venue
      end

      duplicates = event.find_exact_duplicates
      event = duplicates.first.progenitor if duplicates
      event
    end
  end

  # Return the name of the source, which can be its title or URL.
  def name
    [title,url].detect{|t| !t.blank?}
  end

private

  # Ensure that the URL for this source is valid.
  def assert_url
    begin
      URI.parse(url)
      return true
    rescue URI::InvalidURIError => e
      errors.add("url", "has invalid format")
      return false
    end
  end

end
