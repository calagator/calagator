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
require "calagator/decode_html_entities_hack"
require "paper_trail"
require "loofah-activerecord"
require "loofah/activerecord/xss_foliate"

module Calagator

class Source < ActiveRecord::Base
  self.table_name = "sources"

  validate :assert_url

  has_many :events,  :dependent => :destroy
  has_many :venues,  :dependent => :destroy

  scope :listing, -> { order('created_at DESC') }

  has_paper_trail

  xss_foliate
  include DecodeHtmlEntitiesHack

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

end
