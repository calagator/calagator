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
  has_many :events, :dependent => :nullify

  validates_presence_of :title

  # Return an Array of Venues in sorted order.
  def self.find_all_ordered
    Venue.find(:all, :order => "title ASC")
  end

  # Returns a new Venue created from an AbstractLocation.
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

end
