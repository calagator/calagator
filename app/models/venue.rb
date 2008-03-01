# == Schema Information
# Schema version: 4
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

  # Returns a new Venue created from an AbstractLocation
  def self.from_abstract_location(abstract_location)
    returning Venue.new do |venue|
      unless abstract_location.blank?
        abstract_location.each_pair do |key, value|
          venue.send("#{key}=", value) unless value.blank?
        end
      end
    end
  end
end
