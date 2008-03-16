# == Schema Information
# Schema version: 7
#
# Table name: sources
#
#  id          :integer         not null, primary key
#  title       :string(255)
#  url         :string(255)
#  format_type :string(255)
#  imported_at :datetime
#  created_at  :datetime
#  updated_at  :datetime
#

require 'uri'

# == Source
#
# A model that represents a source of events data, such as feeds for hCal, iCal, etc.
class Source < ActiveRecord::Base

  has_many :events

  # Ensure that #url and #format_type are valid.
  def validate
    if SourceParser.known_format_types.grep(/#{format_type}/i).size != 1
      errors.add("format_type", "has invalid format")
    end

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
    if valid?
      opts[:url] ||= url
      returning([]) do |events|
        SourceParser.to_abstract_events(format_type, opts).each do |abstract_event|
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
