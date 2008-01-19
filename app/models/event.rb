# == Schema Information
# Schema version: 3
#
# Table name: events
#
#  id          :integer         not null, primary key
#  title       :string(255)     
#  description :text            
#  start_time  :datetime        
#  url         :string(255)     
#  created_at  :datetime        
#  updated_at  :datetime        
#  venue_id    :integer         
#

class Event < ActiveRecord::Base
  belongs_to :venue
end
