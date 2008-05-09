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

  has_many :events
  has_many :updates

  def validate
    begin
      URI.parse(url)
    rescue URI::InvalidURIError => e
      errors.add("url", "has invalid format")
    end
  end

  # Normalize the URL.
  def url=(value)
    begin
      url = URI.parse(value)
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
      opts[:url] ||= url
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

  def name
    title || url
  end
end
