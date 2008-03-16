# == Schema Information
# Schema version: 7
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
  include DuplicateChecking
  has_many :events, :dependent => :nullify
  belongs_to :source

  validates_presence_of :title

  # Returns a new Venue created from an AbstractLocation.
  def self.from_abstract_location(abstract_location, source=nil)
    venue = Venue.new

    unless abstract_location.blank?
      venue.source = source
      abstract_location.each_pair do |key, value|
        venue[key] = value unless value.blank?
      end
    end

    duplicates = venue.find_exact_duplicates
    duplicates ? duplicates.first : venue
  end

  # Does this venue have any address information?
  def has_full_address?
    !"#{street_address}#{locality}#{region}#{postal_code}#{country}".blank?
  end

  # Display a single line address.
  def full_address()
    if has_full_address?
      "#{street_address}, #{locality} #{region} #{postal_code} #{country}"
    else
      nil
    end
  end

end
