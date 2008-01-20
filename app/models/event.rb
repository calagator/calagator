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

require 'htmlentities'

# == Event
#
# A model representing a calendar event.
class Event < ActiveRecord::Base
  belongs_to :venue

  HTMLEntitiesCoder = HTMLEntities.new

  # Returns a new Event created from an hCalendar event.
  def self.from_hcal(hcal)
    event = Event.new
    for event_field, mofo_field in {
      :title => :summary,
      :description => :description,
      :start_time => :dtstart,
      :url => :url,
    }
      next unless hcal.respond_to?(mofo_field)
      raw_field = hcal.send(mofo_field)
      decoded_field = \
        case mofo_field
        when :dtstart # Don't convert
        else HTMLEntitiesCoder.decode(raw_field)
        end
      event[event_field] = decoded_field || raw_field
    end
    return event
  end
end
