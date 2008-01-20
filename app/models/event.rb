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

# == Event
#
# A model representing a calendar event.
class Event < ActiveRecord::Base
  belongs_to :venue

  # Returns a new Event created from an hCalendar event.
  def self.from_hcal(hcal)
    return Event.new(:title => hcal.summary, :description => hcal.description, :start_time => hcal.dtstart, :url => hcal.url)
  end
end
