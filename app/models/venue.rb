# == Schema Information
# Schema version: 3
#
# Table name: venues
#
#  id          :integer         not null, primary key
#  title       :string(255)     
#  description :text            
#  address     :string(255)     
#  url         :string(255)     
#  created_at  :datetime        
#  updated_at  :datetime        
#

class Venue < ActiveRecord::Base
end
