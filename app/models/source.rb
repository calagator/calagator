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

  # Create events from list of +urls+. Returns the events created.
  def self.create_events_for!(*urls)
    urls.flatten!
    created_events = []
    urls.each do |url|
      source = Source.find_or_create_by_url(:url => url)
      created_events += source.create_events!
    end
    return created_events
  end

  # Create events for this source. Returns the events created. URL must be set
  # for this source for this to work.
  def create_events!
    return to_events.map{|event| event.save!; event}
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
    self.save
    if valid?
      opts[:url] ||= self.url
      returning([]) do |events|
        SourceParser.to_abstract_events(opts).each do |abstract_event|
          event = Event.from_abstract_event(abstract_event, self)
          
          events << event
        end
      end
    else
      raise ActiveRecord::RecordInvalid, "Invalid record: #{errors.full_messages.to_sentence}"
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
