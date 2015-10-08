# == Schema Information
# Schema version: 20110604174521
#
# Table name: venues
#
#  id              :integer         not null, primary key
#  title           :string(255)
#  description     :text
#  address         :string(255)
#  url             :string(255)
#  created_at      :datetime
#  updated_at      :datetime
#  street_address  :string(255)
#  locality        :string(255)
#  region          :string(255)
#  postal_code     :string(255)
#  country         :string(255)
#  latitude        :decimal(, )
#  longitude       :decimal(, )
#  email           :string(255)
#  telephone       :string(255)
#  source_id       :integer
#  duplicate_of_id :integer
#  version         :integer
#  closed          :boolean
#  wifi            :boolean
#  access_notes    :text
#  events_count    :integer
#
require "calagator/decode_html_entities_hack"
require "calagator/strip_whitespace"
require "calagator/url_prefixer"
require "paper_trail"
require "loofah-activerecord"
require "loofah/activerecord/xss_foliate"
require "validate_url"

module Calagator

class Venue < ActiveRecord::Base
  self.table_name = "venues"

  include StripWhitespace

  has_paper_trail
  acts_as_taggable

  xss_foliate :sanitize => [:description, :access_notes]
  include DecodeHtmlEntitiesHack

  # Associations
  has_many :events, -> { non_duplicates }, dependent: :nullify
  belongs_to :source

  # Triggers
  strip_whitespace! :title, :description, :address, :url, :street_address, :locality, :region, :postal_code, :country, :email, :telephone
  before_save :geocode!

  # Validations
  validates :title, presence: true
  validates :url, url: { allow_blank: true }
  validates :latitude, inclusion: { in: -90..90, allow_nil: true }
  validates :longitude, inclusion: { in: -180..180, allow_nil: true }
  validates :title, :description, :address, :url, :street_address, :locality, :region, :postal_code, :country, :email, :telephone, blacklist: true

  # Duplicates
  include DuplicateChecking
  duplicate_checking_ignores_attributes    :source_id, :version, :closed, :wifi, :access_notes
  duplicate_squashing_ignores_associations :tags, :base_tags, :taggings
  duplicate_finding_scope -> { non_duplicates.order(:title, :id) }

  # Named scopes
  scope :masters,          -> { non_duplicates.includes(:source, :events, :tags, :taggings) }
  scope :with_public_wifi, -> { where(wifi: true) }
  scope :in_business,      -> { where(closed: false) }
  scope :out_of_business,  -> { where(closed: true) }

  def self.search(query, opts={})
    SearchEngine.search(query, opts)
  end

  def url=(value)
    super UrlPrefixer.prefix(value)
  end

  # Display a single line address.
  def full_address
    full_address = "#{street_address}, #{locality} #{region} #{postal_code} #{country}"
    full_address.strip != "," && full_address
  end

  # Get an address we can use for geocoding
  def geocode_address
    full_address or address
  end

  # Return this venue's latitude/longitude location,
  # or nil if it doesn't have one.
  def location
    location = [latitude, longitude]
    location.all?(&:present?) && location
  end

  attr_accessor :force_geocoding

  def geocode!
    Geocoder.geocode(self)
    true # Try to geocode, but don't complain if we can't.
  end

  def update_events_count!
    update_attribute(:events_count, events.non_duplicates.count)
  end
end

end
