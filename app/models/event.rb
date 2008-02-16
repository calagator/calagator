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

  # Returns a new Event created from an AbstractEvent.
  def self.from_abstract_event(abstract_event)
    venue = Venue.create(:title => abstract_event.location, :description => abstract_event.location)
    returning Event.new do |event|
      event.title        = abstract_event.title
      event.description  = abstract_event.description
      event.start_time   = abstract_event.start_time 
      event.url          = abstract_event.url
      event.venue_id     = venue.id
    end
  end
    
  def to_hcal
    <<-EOF
<div class="vevent">
<a class="url" href="#{url}">#{url}</a>
<span class="summary">#{title}</span>: 
<abbr class="dtstart" title="#{start_time.to_s(:yyyymmdd)}">#{start_time.to_s(:long_date).gsub(/\b[0](\d)/, '\1')}</abbr>,
at the <span class="location">#{venue && venue.title}</span>
</div>
EOF
  end
end
