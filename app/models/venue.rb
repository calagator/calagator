# == Schema Information
# Schema version: 14
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
#

class Venue < ActiveRecord::Base
  # Solr
  unless RAILS_ENV == 'test'
      acts_as_solr
  end

  # Associations
  has_many :events, :dependent => :nullify
  belongs_to :source

  # Triggers
  before_validation :normalize_url!
  before_save :geocode

  # Validations
  validates_presence_of :title
  validates_format_of :url,
    :with => /(http|https):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/,
    :allow_blank => true,
    :allow_nil => true
  validates_inclusion_of :latitude, :longitude,
    :in => -180..180,
    :allow_nil => true,
    :message => "must be between -180 and 180"

  # Duplicates
  include DuplicateChecking
  self.ignore_attributes << :source_id

  #===[ Instantiators ]===================================================

  # Returns a new Venue created from an AbstractLocation.
  def self.from_abstract_location(abstract_location, source=nil)
    venue = Venue.new

    unless abstract_location.blank?
      venue.source = source
      abstract_location.each_pair do |key, value|
        venue[key] = value unless value.blank?
      end
    end

    # if the new venue has no exact duplicate, use the new venue
    # otherwise, find the ultimate master and return it
    duplicates = venue.find_exact_duplicates
    if duplicates
      venue = duplicates.first
      while venue.duplicate_of_id do
        venue = Venue.find(venue.duplicate_of_id)
      end
    end
    return venue

  end

  #===[ Finders ]=========================================================

  # Returns future events for this venue.
  def find_future_events(opts={})
    opts[:venue] = self
    Event.find_future_events(opts)
  end

  #===[ Address helpers ]=================================================

  # Does this venue have any address information?
  def has_full_address?
    !"#{street_address}#{locality}#{region}#{postal_code}#{country}".blank?
  end

  # Display a single line address.
  def full_address
    if has_full_address?
      "#{street_address}, #{locality} #{region} #{postal_code} #{country}"
    else
      nil
    end
  end

  #===[ Geocoding helpers ]===============================================

  # Get an address we can use for geocoding
  def geocode_address
    full_address or address
  end

  # Return this venue's latitude/longitude location,
  # or nil if it doesn't have one.
  def location
    [latitude, longitude] unless latitude.blank? or longitude.blank?
  end

  # Should we default to forcing geocoding when the user edits this venue?
  def force_geocoding
    location.nil? # Yes, if it has no location.
  end

  # Maybe trigger geocoding when we save
  def force_geocoding=(force_it)
    self.latitude = self.longitude = nil if force_it
  end

  # Try to geocode, but don't complain if we can't.
  def geocode
    unless location or geocode_address.blank? or duplicate_of
      geo = GeoKit::Geocoders::MultiGeocoder.geocode(geocode_address)
      if geo.success
        self.latitude       = geo.lat
        self.longitude      = geo.lng
        self.street_address = geo.street_address if self.street_address.blank?
        self.locality       = geo.city           if self.locality.blank?
        self.region         = geo.state          if self.region.blank?
        self.postal_code    = geo.zip            if self.postal_code.blank?
        self.country        = geo.country_code   if self.country.blank?
      end
      # puts "Geocoding #{geo.success ? "successful" : "failed"}: #{geo.inspect}"
    end

    return true
  end

  #===[ Triggers ]========================================================

  def normalize_url!
    unless self.url.blank? || self.url.match(/^[\d\D]+:\/\//)
      self.url = 'http://' + self.url
    end
  end

end
