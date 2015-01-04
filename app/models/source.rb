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
    return new(attrs) unless attrs[:url]

    source = find_or_create_by_url(attrs[:url])
    source.reimport = true if attrs.delete(:reimport)
    source.attributes = attrs
    source.save if source.changed?
    source
  end

  # Create events for this source. Returns the events created. URL must be set
  # for this source for this to work.
  def create_events!(opts={})
    save!
    events = to_events(opts).select(&:valid?)
    events.reject!(&:old?) if opts[:skip_old]
    events.each(&:save!)
    events
  end

  # Normalize the URL.
  def url=(value)
    url = URI.parse(value.strip)
    url.scheme = 'http' unless ['http','https','ftp'].include?(url.scheme) || url.scheme.nil?
    write_attribute(:url, url.scheme.nil? ? 'http://'+value.strip : url.to_s)
  rescue URI::InvalidURIError
    false
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
    opts[:source] = self
    Source::Parser.to_events(opts)
  end

  # Return the name of the source, which can be its title or URL.
  def name
    [title, url].detect(&:present?)
  end

  private

  # Ensure that the URL for this source is valid.
  def assert_url
    URI.parse(url)
  rescue URI::InvalidURIError
    errors.add :url, "has invalid format"
    false
  end
end
