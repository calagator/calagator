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
    returning Event.new do |event|
      event.title        = abstract_event.title
      event.description  = abstract_event.description
      event.start_time   = abstract_event.start_time 
      event.url          = abstract_event.url        
    end
  end
  
  
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
