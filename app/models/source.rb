# == Schema Information
# Schema version: 20080705164959
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
  Tag # this class uses tagging. referencing the Tag class ensures that has_many_polymorphs initializes correctly across reloads.
  
  unless RAILS_ENV == 'test'
      acts_as_solr
  end
  validate :assert_url

  has_many :events
  has_many :updates

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
    transaction do
      for event in self.to_events(opts)
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
    end
    return events
  end

  # Normalize the URL.
  def url=(value)
    begin
      url = URI.parse(value.strip)
      url.scheme = 'http' unless ['http','https','ftp'].include?(url.scheme) || url.scheme.nil?
      write_attribute(:url, url.scheme.nil? ? 'http://'+value.strip : url.to_s)
    rescue URI::InvalidURIError => e
      false
    end
  end

  # Returns an Array of Event objects that were read from this source.
  #
  # Options:
  # * :url -- URL of data to import. Defaults to record's #url attribute.
  # * :skip_old -- Should old events be skipped? Default is true.
  def to_events(opts={})
    self.imported_at = Time.now
    if valid?
      opts[:url] ||= self.url
      returning([]) do |events|
        SourceParser.to_abstract_events(opts).each do |abstract_event|
          event = Event.from_abstract_event(abstract_event, self)

          events << event
        end
      end
    else
      raise ActiveRecord::RecordInvalid, self
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
