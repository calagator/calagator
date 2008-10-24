# == Schema Information
# Schema version: 20080705164959
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
  Tag # this class uses tagging. referencing the Tag class ensures that has_many_polymorphs initializes correctly across reloads.

  # Names of columns and methods to create Solr indexes for
  INDEXABLE_FIELDS = \
    %w(
      title
      description
      address
      url
      street_address
      locality
      region
      postal_code
      country
      latitude
      longitude
      email
      telephone
      tag_list
    ).map(&:to_sym)

  unless RAILS_ENV == 'test'
    acts_as_solr :fields => INDEXABLE_FIELDS
  end
  
  acts_as_versioned

  include VersionDiff

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

  include ValidatesBlacklistOnMixin
  validates_blacklist_on :title, :description, :address, :url, :street_address, :locality, :region, :postal_code, :country, :email, :telephone

  # Duplicates
  include DuplicateChecking
  duplicate_checking_ignores_attributes    :source_id, :version
  duplicate_squashing_ignores_associations :tags

  # Named scopes
  named_scope :masters,
    :conditions => ['duplicate_of_id IS NULL'],
    :include => [:source, :events, :tags, :taggings]

  #===[ Instantiators ]===================================================

  # Returns a new Venue for the +abstract_location+ retrieved from +source+.
  def self.from_abstract_location(abstract_location, source=nil)
    venue = Venue.new

    # TODO Figure out if +abstract_location+ can ever be blank. If it can be blank, rework the later code in this method so that #geocode and duplicate finders aren't called on an effectively blank record. If it can't be blank, remove this unnecessary "unless" conditional.
    unless abstract_location.blank?
      venue.source = source if source
      abstract_location.each_pair do |key, value|
        venue[key] = value unless value.blank?
      end
    end

    # We must add geocoding information so this venue can be compared to existing ones.
    venue.geocode

    # if the new venue has no exact duplicate, use the new venue
    # otherwise, find the ultimate master and return it
    duplicates = venue.find_exact_duplicates
    venue = duplicates.first.progenitor if duplicates
    return venue
  end

  #===[ Finders ]=========================================================

  # Returns future events for this venue. Accepts the same +opts+ as Event.find_future_events.
  def find_future_events(opts={})
    opts[:venue] = self
    Event.find_future_events(opts)
  end

  # Return Hash of Venues grouped by the +type+, e.g., a 'title'.
  # TODO Consider renaming "type" in the method name and arguments to 'attribute'. ActiveRecord uses the term 'type' to mean a STI (Single Table Inheritance) class field, while 'attribute' is analogous to a table's column.
  def self.find_duplicates_by_type(type='title')
    if type == 'na'
      return { [] => self.find(:non_duplicates, :order => 'lower(title)')}
    else
      kind = %w[all any].include?(type) ? type.to_sym : type.split(',')
      return self.find_duplicates_by(kind, :grouped => true)
    end
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
  # TODO Consider renaming this to #add_geocoding! to imply that this method makes destructive changes the object, rather than just returning values. Compare its name to the method called #geocode_address, which just returns values.
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
