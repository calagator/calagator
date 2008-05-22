# == Schema Information
# Schema version: 14
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

  has_many :events
  has_many :updates

  # Create sources and events for the Array of +urls+. Returns a Hash of
  # Sources and the Events created.
  def self.create_sources_and_events_for!(*urls)
    sources2events = {}
    transaction do
      urls.flatten.each do |url|
        source = Source.find_or_create_by_url(:url => url)
        events = source.create_events!
        sources2events[source] = events
        source.save! # Updates the imported_at and othe fields
      end
    end
    return sources2events
  end

  # Create events for this source. Returns the events created. URL must be set
  # for this source for this to work.
  def create_events!
    now = Time.now.yesterday # All events before this date will be skipped
    events = []
    transaction do
      for event in self.to_events
        next if event.title.blank? && event.description.blank? && event.url.blank?
        next if event.start_time < now
        
        event.save!
        event.venue.save! if event.venue
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
      url.scheme = 'http' unless ['http','ftp'].include?(url.scheme) || url.scheme.nil?
      write_attribute(:url, url.scheme.nil? ? 'http://'+value.strip : url.to_s)
    rescue URI::InvalidURIError => e
      false
    end
  end

  # Returns an Array of Event objects that were read from this source.
  def to_events(opts={})
    self.imported_at = DateTime.now()
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
