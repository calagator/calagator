# == Schema Information
# Schema version: 6
#
# Table name: venues
#
#  id             :integer         not null, primary key
#  title          :string(255)
#  description    :text
#  address        :string(255)
#  url            :string(255)
#  created_at     :datetime
#  updated_at     :datetime
#  street_address :string(255)
#  locality       :string(255)
#  region         :string(255)
#  postal_code    :string(255)
#  country        :string(255)
#  latitude       :float
#  longitude      :float
#  email          :string(255)
#  telephone      :string(255)
#

class Venue < ActiveRecord::Base
  has_many :events

  validates_presence_of :title

  # Return an Array of all sensible Venues, sorted by the title.
  def self.find_all_sensible
    Venue.find(:all, :order => "title ASC").select{|venue| venue.sensible?}
  end

  def self.find_all_sensible_with_current(current)
    results = find_all_sensible
    results.unshift(current) if current && !current.sensible?
    return results
  end

  def sensible?
    !read_attribute(:title).blank?
  end

  def title_or_filler
    value = read_attribute(:title)
    value.blank? ? "Venue ##{id}" : value
  end

  # Returns a new Venue created from an AbstractLocation
  def self.from_abstract_location(abstract_location)
    returning Venue.new do |venue|
      unless abstract_location.blank?
        abstract_location.each_pair do |key, value|
          venue[key] = value unless value.blank?
        end
      end
    end
  end
  
  def has_full_address?
    !"#{street_address}#{locality}#{region}#{postal_code}#{country}".blank?
  end

  def full_address()
    "#{street_address}, #{locality} #{region} #{postal_code} #{country}"
  end 
  
  def google_maps_url()
    return "http://maps.google.com/maps?q=#{CGI::escape(full_address)}"
  end
end
