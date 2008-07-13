# == Schema Information
# Schema version: 20080704045101
#
# Table name: events
#
#  id              :integer         not null, primary key
#  title           :string(255)     
#  description     :text            
#  start_time      :datetime        
#  url             :string(255)     
#  created_at      :datetime        
#  updated_at      :datetime        
#  venue_id        :integer         
#  source_id       :integer         
#  duplicate_of_id :integer         
#  end_time        :datetime
#

# == Event
#
# A model representing a calendar event.
class Event < ActiveRecord::Base
  Tag # this class uses tagging. referencing the Tag class ensures that has_many_polymorphs initializes correctly across reloads.
  
  # Names of columns and methods to create Solr indexes for
  INDEXABLE_FIELDS = \
    %w(
      title
      description
      url
      duplicate_for_solr
      start_time_for_solr
      end_time_for_solr
      text_for_solr
    ).map(&:to_sym)
    
  unless RAILS_ENV == 'test'
      acts_as_solr :fields => INDEXABLE_FIELDS
  end
  
  # Associations
  belongs_to :venue
  belongs_to :source

  # Triggers
  before_validation :normalize_url!

  # Validations
  validates_presence_of :title, :start_time
  validate :end_time_later_than_start_time
  validates_format_of :url,
    :with => /(http|https):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/,
    :allow_blank => true,
    :allow_nil => true

  # Duplicates
  include DuplicateChecking
  self.ignore_attributes << :source_id

  #---[ Overrides ]-------------------------------------------------------

  # Index only specific events
  def self.rebuild_solr_index
    # Skip duplicate events
    self.find(:all, :conditions => ['duplicate_of_id IS NULL']).each {|content| content.solr_save}
    logger.debug self.count>0 ? "Index for #{self.name} has been rebuilt" : "Nothing to index for #{self.name}"
  end

  # Return the title but strip out any whitespace.
  def title
    # TODO Generalize this code so we can use it on other attributes in the different model classes. The solution should use an #alias_method_chain to make sure it's not breaking any explicit overrides for an attribute.
    s = read_attribute(:title)
    s.blank? ? nil : s.strip
  end

  #---[ Queries ]---------------------------------------------------------
  
  # Associate this event with the +venue+. The +venue+ can be given as a Venue
  # instance, an ID, or a title.
  def associate_with_venue(venue)
    venue = \
      case venue
      when Venue    then venue
      when NilClass then nil
      when String   then Venue.find_or_initialize_by_title(venue)
      when Fixnum   then Venue.find(venue)
      else raise TypeError, "Unknown type: #{venue.class}"
      end

    if venue && ((self.venue && self.venue.title != venue.title) || (!self.venue))
      # Set venue if it was nil or had a different title
      self.venue = venue.duplicate? ? venue.duplicate_of : venue
    elsif !venue && self.venue
      # Clear the event's venue field
      self.venue = nil
    end

    return self.venue
  end

  # Returns groups of records for the overview screen.
  #
  # The data structure returned maps time names to arrays of event records:
  #   {
  #     :today => [...],
  #     :tomorrow => [...],
  #     :later => [...],
  #   }
  def self.select_for_overview
    today = Time.today.beginning_of_day.utc
    tomorrow = today + 1.day
    after_tomorrow = tomorrow + 1.day
    future_cutoff = today + 2.weeks

    times_to_events = {
      :today    => [],
      :tomorrow => [],
      :later    => [],
    }

    # TODO turn this into a call to find_by_dates
    Event.find(:all,
      :include    => :venue,
      :order      => 'start_time ASC',
      :conditions => [
        # event is out of range if its start_time is after the future cutoff
        # OR its end_time is before today
        'events.duplicate_of_id is NULL AND NOT ((start_time > ?) OR (end_time < ?) )',
        future_cutoff, today 
      ]
    ).each do |event|
      if event.start_time <= tomorrow
        times_to_events[:today]    << event
      elsif event.start_time >= tomorrow && event.start_time <= after_tomorrow
        times_to_events[:tomorrow] << event
      else
        times_to_events[:later]    << event
      end
    end

    return times_to_events
  end

  # Returns an Array of non-duplicate future Event instances.
  # where "future" means any part of an event occurs today or later
  # TODO: fix this to simply call find_by_dates
  #
  # Options:
  # * :order => How to sort events. Defaults to :start_time.
  # * :venue => Which venue to display events for. Defaults to all.
  def self.find_future_events(opts={})
    today = Time.now.beginning_of_day.utc
    order = opts[:order] || :start_time
    conditions_sql = "events.duplicate_of_id IS NULL AND 
      (events.end_time >= :early_cutoff OR events.start_time >= :early_cutoff)"
    conditions_vars = {
      :early_cutoff => today,
      :late_cutoff => today
    }
    if venue = opts[:venue]
      conditions_sql << " AND venues.id == :venue"
      conditions_vars[:venue] = venue.id
    end

    return find(:all,
      :conditions => [conditions_sql, conditions_vars],
      :include => :venue,
      :order => order)
  end

  # Returns an Array of non-duplicate Event instances within a given date range
  # where "within" means that any part of an event is within the range
  # event is out of range if its start_time is after the late cutoff
  # OR its end_time is before the early cutoff
  def self.find_by_dates(early_cutoff, late_cutoff, order='start_time')
    early_cutoff = Time.parse(early_cutoff.to_s) if early_cutoff.is_a?(Date)
    late_cutoff = Time.parse(late_cutoff.to_s).end_of_day if late_cutoff.is_a?(Date)

    find(:all,
      :conditions => [
        'events.duplicate_of_id is NULL AND NOT (start_time > ? OR (end_time < ?) )',
        late_cutoff.utc, early_cutoff.utc
      ],
      :include => :venue,
      :order => order)
  end

  # How similar should terms be to qualify as a match? This value should be
  # close to zero because Lucene's implementation of fuzzy matching is
  # defective, e.g., at 0.5 it can't even realize that "meetin" is similar to
  # "meeting".
  SOLR_SIMILARITY = 0.3

  # How much to boost the score of a match in the title?
  SOLR_TITLE_BOOST = 4

  # Return an Array of non-duplicate Event instances matching the search +query+..
  #
  # Options:
  # * :order => How to order the entries? Can be :score, :date, :name, or :venue.
  #   Defaults to :score.
  # * :limit => Maximum number of entries to return, defaults to 50.
  # * :skip_old => Return old entries? Defaults to false.
  def self.search(query, opts={})
    order_kind = opts[:order].blank? ? :score : opts[:order].to_sym
    order = \
      case order_kind
      when :date  then 'start_time asc'
      when :name  then 'events.title asc'
      when :venue then 'venues.title asc'
      when :score then 'score desc'
      else raise ArgumentError, "Unknown order: #{opts[:order]}"
      end
    skip_old = opts[:skip_old] == true
    limit = opts[:limit] || 50

    formatted_query = \
      %{NOT duplicate_for_solr:"1" AND (} \
      << query \
      .scan(/\S+/) \
      .map(&:escape_lucene) \
      .map{|term| %{title:"#{term}"~#{"%1.1f" % SOLR_SIMILARITY}^#{SOLR_TITLE_BOOST} "#{term}"~#{"%1.1f" % SOLR_SIMILARITY}}} \
      .join(" ") \
      << %{)}

    if skip_old
      formatted_query << %{ AND (start_time:[#{Time.today.yesterday.strftime(SOLR_TIME_FORMAT)} TO #{SOLR_TIME_MAXIMUM}])}
    end

    solr_opts = {
      :order => order,
      :limit => limit,
    }
    solr_opts[:scores] = true if order == :score
    response = Event.find_by_solr(formatted_query, solr_opts)
    results = response.results

    return results
  end

  def self.search_grouped_by_currentness(*args)
    results = self.search(*args).group_by(&:current?)
    return {:current => results[true] || [], :past => results[false] || []}
  end

  #---[ Transformations ]-------------------------------------------------

  # Returns a new Event created from an AbstractEvent.
  def self.from_abstract_event(abstract_event, source=nil)

    event = Event.new

    event.source       = source
    event.title        = abstract_event.title
    event.description  = abstract_event.description
    event.start_time   = Time.parse(abstract_event.start_time.to_s)
    event.end_time     = abstract_event.end_time.blank? ? nil : Time.parse(abstract_event.end_time.to_s)
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

        # dtstamp and uid added because of a bug in Outlook;
        # Outlook 2003 will not import and .ics file unless it has DTSTAMP, UID, and METHOD
        # use created_at for DTSTAMP; if there's no created_at, use event.start_time;
        c.dtstamp       event.created_at || event.start_time
        # TODO substitute correct environment variables for "http://calagator.org/events/"
        c.uid         opts[:url_helper].call(event) if opts[:url_helper]
        # c.uid         ("http://calagator.org/events/" + event.id.to_s)


        # TODO Figure out how to encode a venue. Remember that Vpim can't handle Vvenue itself and our parser had to
        # go through many hoops to extract venues from the source data. Also note that the Vevent builder here doesn't
        # recognize location, priority, and a couple of other things that are included as modules in the Vevent class itself.
        # This seems like a bug in Vpim.
        #c.location     !event.venue.nil? ? event.venue.title : ''
      end
    end

    # TODO Add calendar title support to vpim or find a prettier way to do this.
    # method added because of bug in Outlook 2003, which won't import .ics without a METHOD
    return icalendar.encode.sub(/CALSCALE:Gregorian/, "CALSCALE:Gregorian\nX-WR-CALNAME:Calagator\nMETHOD:PUBLISH")
  end

  def location
    venue && venue.location
  end

  def normalize_url!
    unless self.url.blank? || self.url.match(/^[\d\D]+:\/\//)
      self.url = 'http://' + self.url
    end
  end

  #---[ Date related ]----------------------------------------------------

  # Is this event current? Default cutoff is today
  def current?(cutoff=nil)
    cutoff ||= Time.today
    return (self.end_time || self.start_time) >= cutoff
  end

  # Is this event old? Default cutoff is yesterday
  def old?(cutoff=nil)
    cutoff ||= Time.now.yesterday
    return (self.end_time || self.start_time) < cutoff
  end

  #---[ Solr helpers ]----------------------------------------------------

  SOLR_TIME_FORMAT = '%Y%m%d%H%M'
  SOLR_TIME_LENGTH = Time.now.strftime(SOLR_TIME_FORMAT).length
  SOLR_TIME_MAXIMUM = ('9' * SOLR_TIME_LENGTH).to_i

  # Return a purely numeric representation of the start_time
  def start_time_for_solr
    time = self.start_time
    time ? time.utc.strftime(SOLR_TIME_FORMAT).to_i : nil
  end

  # Return a purely numeric representation of the end_time
  def end_time_for_solr
    time = self.end_time
    time ? time.utc.strftime(SOLR_TIME_FORMAT).to_i : nil
  end

  # Returns value for whether the record is a duplicate or not
  def duplicate_for_solr
    self.duplicate_of_id.blank? ? 0 : 1
  end

  # Return a string of all indexable fields, which may be useful for doing duplicate checks
  def text_for_solr
    INDEXABLE_FIELDS.reject{|name| name == :text_for_solr}.map{|name| self.send(name)}.join("|")
  end

protected

  def end_time_later_than_start_time
    errors.add(:end_time, "End cannot be before start") \
      unless end_time.nil? or end_time >= start_time
  end
end
