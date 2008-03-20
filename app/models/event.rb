# == Schema Information
# Schema version: 7
#
# Table name: events
#
#  id          :integer         not null, primary key
#  title       :string(255)     
#  description :text            
#  start_time  :datetime        
#  venue_id    :integer         
#  url         :string(255)     
#  created_at  :datetime        
#  updated_at  :datetime        
#  end_time    :datetime        
#  source_id   :integer         
#

require 'vpim/icalendar'

# == Event
#
# A model representing a calendar event.
class Event < ActiveRecord::Base
  include DuplicateChecking
  belongs_to :venue
  belongs_to :source
  validates_presence_of :title, :start_time

  #---[ Overrides ]-------------------------------------------------------

  # Return the title but strip out any whitespace.
  def title
    # TODO Generalize this code so we can use it on other attributes in the different model classes. The solution should use an #alias_method_chain to make sure it's not breaking any explicit overrides for an attribute.
    s = read_attribute(:title)
    s.blank? ? nil : s.strip
  end

  #---[ Queries ]---------------------------------------------------------

  # Returns an Array of future Event instances.
  def self.find_all_future_events(order)
    return find(:all, :conditions => [ 'start_time > ?', Date.today ], 
              :include => :venue, 
              :order => order)
  end
  
  # Returns an Array of Event instances within a given date range
  def self.find_by_dates(start_date, end_date, order='start_time')
    find(:all, :conditions => ['start_time > ? AND start_time < ?', start_date, end_date], 
        :include => :venue,
        :order => order)
  end

  #---[ Transformations ]-------------------------------------------------

  # Returns a new Event created from an AbstractEvent.
  def self.from_abstract_event(abstract_event, source=nil)
    event = Event.new

    event.source       = source
    event.title        = abstract_event.title
    event.description  = abstract_event.description
    event.start_time   = abstract_event.start_time
    event.url          = abstract_event.url
    event.venue        = Venue.from_abstract_location(abstract_event.location, source) if abstract_event.location

    duplicates = event.find_exact_duplicates
    duplicates ? duplicates.first : event
  end

  # Returns an hCalendar string representing this Event.
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

  # Returns an iCalendar string representing this Event.
  #
  # Options:
  # * :url_helper - Lambda that accepts an Event instance and generates a URL
  #   for it if it doesn't have a URL already. (See Event::to_ical for example)
  def to_ical(opts={})
    self.class.to_ical(self, opts)
  end

  # Return an iCalendar string representing an Array of Event instances.
  #
  # Arguments:
  # * :events - Event instance or array of them.
  #
  # Options:
  # * :url_helper - Lambda that accepts an Event instance and generates a URL
  #   for it if it doesn't have a URL already.
  #
  # Example:
  #   ics1 = Event.to_ical(myevent)
  #   ics2 = Event.to_ical(myevents, :url_helper => lambda{|event| event_url(event)})
  def self.to_ical(events, opts={})
    events = [events].flatten
    icalendar = Vpim::Icalendar.create2

    for event in events
      next if event.start_time.nil?
      icalendar.add_event do |c|
        c.dtstart       event.start_time
        c.dtend         event.end_time || event.start_time+1.hour
        c.summary       event.title || 'Untitled Event'
        c.description   event.description if event.description
        c.created       event.created_at if event.created_at
        c.lastmod       event.updated_at if event.updated_at

        # TODO Come up with a generalized way to generate URLs for events that don't have them. 
        # The reason for this messy URL helper business is that models can't access the route helpers, 
        # and even if they could, they'd need to access the request object so they know what the server's name is and such.
        if event.url.blank?
          c.url         opts[:url_helper].call(event) if opts[:url_helper]
        else
          c.url         event.url
        end

        # TODO Figure out how to encode a venue. Remember that Vpim can't handle Vvenue itself and our parser had to 
        # go through many hoops to extract venues from the source data. Also note that the Vevent builder here doesn't 
        # recognize location, priority, and a couple of other things that are included as modules in the Vevent class itself. 
        # This seems like a bug in Vpim.
        #c.location     !event.venue.nil? ? event.venue.title : ''
      end
    end
    
    # TODO Add calendar title support to vpim or find a prettier way to do this.
    return icalendar.encode.sub(/CALSCALE:Gregorian/, "CALSCALE:Gregorian\nX-WR-CALNAME:Calagator")
  end
  
  def location
    venue && venue.location
  end
end

