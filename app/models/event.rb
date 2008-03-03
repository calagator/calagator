# == Schema Information
# Schema version: 6
#
# Table name: events
#
#  id          :integer         not null, primary key
#  title       :string(255)     
#  description :text            
#  start_time  :datetime        
#  end_time    :datetime        
#  venue_id    :integer         
#  url         :string(255)     
#  source_id   :integer         
#  created_at  :datetime        
#  updated_at  :datetime        
#

# == Event
#
# A model representing a calendar event.
class Event < ActiveRecord::Base
  belongs_to :venue
  belongs_to :source
  validates_presence_of :title, :start_time

  def self.find_all_future_events
    return find(:all, :conditions => [ 'start_time > ?', Date.today ], :order => 'start_time ASC')
  end

  # Returns a new Event created from an AbstractEvent.
  def self.from_abstract_event(abstract_event)
    returning Event.new do |event|
      event.title        = abstract_event.title
      event.description  = abstract_event.description
      event.start_time   = abstract_event.start_time
      event.url          = abstract_event.url
      event.venue        = Venue.from_abstract_location(abstract_event.location) if abstract_event.location
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
