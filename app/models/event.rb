# == Schema Information
# Schema version: 20080705164959
#
# Table name: events
#
#  id              :integer         not null, primary key
#  title           :string(255)
#  description     :text
#  start_time      :datetime
#  venue_id        :integer
#  url             :string(255)
#  created_at      :datetime
#  updated_at      :datetime
#  source_id       :integer
#  duplicate_of_id :integer
#  end_time        :datetime
#

# == Event
#
# A model representing a calendar event.
class Event < ActiveRecord::Base
  include SearchEngine

  Tag # this class uses tagging. referencing the Tag class ensures that has_many_polymorphs initializes correctly across reloads.

  # Treat any event with a duration of at least this many hours as a multiday
  # event. This constant is used by the #multiday? method and is primarily
  # meant to make iCalendar exports display this event as covering a range of
  # days, rather than hours.
  MIN_MULTIDAY_DURATION = 20.hours

  has_paper_trail

  # Associations
  belongs_to :venue, :counter_cache => true
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

  include ValidatesBlacklistOnMixin
  validates_blacklist_on :title, :description, :url

  include VersionDiff

  # Duplicates
  include DuplicateChecking
  duplicate_checking_ignores_attributes    :source_id, :version
  duplicate_squashing_ignores_associations :tags

  # Named scopes
  named_scope :masters,
    :conditions => ["events.duplicate_of_id IS NULL"],
    :include => [:source, :venue, :tags, :taggings]

  #---[ Overrides ]-------------------------------------------------------

  # Return the title but strip out any whitespace.
  def title
    # TODO Generalize this code so we can use it on other attributes in the different model classes. The solution should use an #alias_method_chain to make sure it's not breaking any explicit overrides for an attribute.
    return read_attribute(:title).to_s.strip
  end

  # Return description without those pesky carriage-returns.
  def description
    # TODO Generalize this code so we can reuse it on other attributes.
    return read_attribute(:description).to_s.gsub("\r\n", "\n").gsub("\r", "\n")
  end

  if (table_exists? rescue nil)
    # XXX Horrible hack to materialize the #start_time= and #end_time= methods so they can be aliased by #start_time_with_smarter_setter= and #end_time_with_smarter_setter=.
    Event.new(:start_time => Time.now, :end_time => Time.now)

    # Set the start_time from one of a number of time values, a string, or an
    # array of strings.
    def start_time_with_smarter_setter=(value)
      return self.class.set_time_on(self, :start_time, value)
    end
    alias_method_chain :start_time=, :smarter_setter

    # Set the end_time to the given +value+, which could be a Time, Date,
    # DateTime, String, Array of Strings, etc.
    def end_time_with_smarter_setter=(value)
      return self.class.set_time_on(self, :end_time, value)
    end
    alias_method_chain :end_time=, :smarter_setter
  end

  # Set the time in Event +record+ instance for an +attribute+ (e.g.,
  # :start_time) to +value+ (e.g., a Time).
  def self.set_time_on(record, attribute, value)
    result = self.time_for(value)
    case result
    when Exception
      record.errors.add(attribute, "is invalid")
      return record.send("#{attribute}_without_smarter_setter=", nil)
    else
      return record.send("#{attribute}_without_smarter_setter=", result)
    end
  end

  # Return the time for the +value+, which could be a Time, Date, DateTime,
  # String, Array of Strings, etc.
  def self.time_for(value)
    value = value.join(' ') if value.kind_of?(Array)
    case value
    when NilClass
      return nil
    when String
      return nil if value.blank?
      begin
        return Time.parse(value)
      rescue Exception => e
        return e
      end
    when Date, Time, DateTime, ActiveSupport::TimeWithZone
      return value # Accept as-is.
    else
      raise TypeError, "Unknown type #{value.class.to_s.inspect} with value #{value.inspect}"
    end
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

    if venue && ((self.venue && self.venue != venue) || (!self.venue))
      # Set venue if one is provided and it's different than the current, or no venue is currently set.
      self.venue = venue.progenitor
    elsif !venue && self.venue
      # Clear the event's venue field
      self.venue = nil
    end

    return self.venue
  end

  # Returns groups of records for the site overview screen in the following format:
  #
  #   {
  #     :today => [...],    # Events happening today or empty array
  #     :tomorrow => [...], # Events happening tomorrow or empty array
  #     :later => [...],    # Events happening within two weeks or empty array
  #     :more => ...,       # First event after the two week window or nil
  #   }
  def self.select_for_overview
    today = Time.today
    tomorrow = today + 1.day
    after_tomorrow = tomorrow + 1.day
    future_cutoff = today + 2.weeks

    times_to_events = {
      :today    => [],
      :tomorrow => [],
      :later    => [],
      :more     => nil,
    }

    # Find all events between today and future_cutoff, sorted by start_time
    # includes events any part of which occurs on or after today through on or after future_cutoff
    overview_events = Event.find_by_dates(today.utc, future_cutoff, :order => :start_time)
    overview_events.each do |event|
      if event.start_time < tomorrow
        times_to_events[:today]    << event
      elsif event.start_time >= tomorrow && event.start_time < after_tomorrow
        times_to_events[:tomorrow] << event
      else
        times_to_events[:later]    << event
      end
    end

    # Find next item beyond the future_cuttoff for use in making links to it:
    times_to_events[:more] = Event.first(:conditions => ["start_time >= ?", future_cutoff], :order => 'start_time asc')

    return times_to_events
  end

  # last Time representable in certain operating systems is Jan 18 2038, local time
  # TODO rewrite SQL in find_by_dates to eliminate the need for this constant
  #   also re-write call find_future_events
  #   see r1048 which has been reverted because it broke find_future_events
  END_OF_TIME = Time.local(2038, 01, 18).yesterday.end_of_day.utc

  # Returns an Array of non-duplicate future Event instances.
  # where "future" means any part of an event occurs today or later
  # Options:
  # * :order => How to sort events. Defaults to :start_time.
  # * :venue => Which venue to display events for. Defaults to all
  def self.find_future_events(opts={})
    order = opts[:order] || :start_time
    venue = opts[:venue]
    Event.find_by_dates(Time.today.utc, END_OF_TIME, :order => order, :venue => venue)
  end

  # Returns an Array of non-duplicate Event instances in a date range
  # includes event if any part of the event is (on or after the start) and (on or before the end)
  # Options:
  # * :order => How to sort events. Defaults to :start_time.
  # * :venue => Which venue to display events for. Defaults to all.
  def self.find_by_dates(start_of_range, end_of_range, opts={})
    start_of_range = Time.parse(start_of_range.to_s) if start_of_range.is_a?(Date)
    end_of_range = Time.parse(end_of_range.to_s).end_of_day if end_of_range.is_a?(Date)
    order = opts [:order] || :start_time

    # event is in range if start_time is in range
    # an event with an end_time is out of range if
    #  its start_time is after the end of range OR its end_time is before the start of the range
    conditions_sql = <<-HERE
      ( (start_time >= :start_of_range AND start_time <= :end_of_range) OR
        (end_time IS NOT NULL AND
          NOT (start_time > :end_of_range OR end_time < :start_of_range ) ) )
    HERE

    conditions_vars = {
      :start_of_range => start_of_range.utc,
      :end_of_range => end_of_range.utc }

    if venue = opts[:venue]
      conditions_sql << " AND venues.id = :venue"
      conditions_vars[:venue] = venue.id
    end

    return self.masters.find(:all,
      :conditions => [conditions_sql, conditions_vars],
      :order => order)
  end

  # Return Hash of Events grouped by the +type+.
  def self.find_duplicates_by_type(type='na')
    case type.to_s.strip
    when 'na', ''
      return { [] => self.find_future_events }
    else
      kind = %w[all any].include?(type) ? type.to_sym : type.split(',')
      return self.find_duplicates_by(kind,
        :grouped => true,
        :where => "a.start_time >= #{self.connection.quote(Time.now - 1.day)}")
    end
  end

  #---[ Sort labels ]-------------------------------------------

  # Labels displayed for sorting options:
  SORTING_LABELS = {
    'name'  => 'Event Name',
    'venue' => 'Location',
    'score' => 'Relevance',
    'date'  => 'Date',
  }

  # Return the label for the +sorting_key+ (e.g. 'score'). Optionally set the
  # +is_searching_by_tag+, to constrain options available for tag searches.
  def self.sorting_label_for(sorting_key=nil, is_searching_by_tag=false)
    sorting_key = sorting_key.to_s
    if sorting_key.present? and SORTING_LABELS.has_key?(sorting_key)
      SORTING_LABELS[sorting_key]
    elsif is_searching_by_tag
      SORTING_LABELS['date']
    else
      SORTING_LABELS['score']
    end
  end

  #---[ Searching ]------------------------------------------------------- 
  
  # NOTE: The `Event.search` method is implemented elsewhere! For example, it's
  # added by SearchEngine::ActsAsSolr if you're using that search engine.

  # Return events matching given +tag+ grouped by their currentness, see
  # ::group_by_currentness for data structure details.
  #
  # Options:
  # * :current => Limit results to only current events? Defaults to false.
  def self.search_tag_grouped_by_currentness(tag, opts={})
    case opts[:order]
      when 'name', 'title'
        opts[:order] = 'events.title'
      when 'date'
        opts[:order] = 'events.start_time'
      when 'venue'
        opts[:order] = 'venues.title'
        opts[:include] = :venue
    end

    result = self.group_by_currentness(self.tagged_with(tag, opts))
    # TODO Avoid searching for :past results. Currently finding them and discarding them when not wanted.
    result[:past] = [] if opts[:current]
    return result
  end

  # Return events grouped by their currentness. Accepts the same +args+ as
  # #search. The results hash is keyed by whether the event is current
  # (true/false) and the values are arrays of events.
  def self.search_keywords_grouped_by_currentness(query, opts={})
    events = self.group_by_currentness(self.search(query, opts))
    if events[:past] && opts[:order].to_s == "date"
      events[:past].reverse!
    end
    return events
  end

  # Return +events+ grouped by currentness using a data structure like:
  #
  #   {
  #     :current => [ my_current_event, my_other_current_event ],
  #     :past => [ my_past_event ],
  #   }
  def self.group_by_currentness(events)
    grouped = events.group_by(&:current?)
    return {:current => grouped[true] || [], :past => grouped[false] || []}
  end

  #---[ Transformations ]-------------------------------------------------

  # Returns an Event created from an AbstractEvent.
  def self.from_abstract_event(abstract_event, source=nil)
    event = Event.new

    event.source       = source
    event.title        = abstract_event.title
    event.description  = abstract_event.description
    event.start_time   = Time.parse(abstract_event.start_time.to_s)
    event.end_time     = abstract_event.end_time.blank? ? nil : Time.parse(abstract_event.end_time.to_s)
    event.url          = abstract_event.url
    event.venue        = Venue.from_abstract_location(abstract_event.location, source) if abstract_event.location
    event.tag_list     = abstract_event.tags.join(',')

    duplicates = event.find_exact_duplicates
    event = duplicates.first.progenitor if duplicates
    return event
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
    
    icalendar = RiCal.Calendar do |calendar|
      for item in events
        calendar.event do |entry|
          entry.summary(item.title || 'Untitled Event')
          
          desc = String.new.tap do |d|
            if item.multiday?
              d << "This event runs from #{TimeRange.new(item.start_time, item.end_time, :format => :text).to_s}."
              d << "\n\n Description:\n"
            end

            d << Hpricot(item.description).to_plain_text unless item.description.blank?
            d << "\n\nTags:\n#{item.tag_list}" unless item.tag_list.blank?
          end
          
          entry.description(desc) unless desc.blank?
          
          entry.created       item.created_at if item.created_at
          entry.last_modified item.updated_at if item.updated_at

          # Set the iCalendar SEQUENCE, which should be increased each time an
          # event is updated. If an admin needs to forcefully increment the
          # SEQUENCE for all events, they can edit the "config/secrets.yml"
          # file and set the "icalendar_sequence_offset" value to something
          # greater than 0.
          entry.sequence((SECRETS.icalendar_sequence_offset || 0) + item.versions.count)
          
          if item.multiday?
            entry.dtstart item.dates.first
            entry.dtend   item.dates.last + 1.day
          else
            entry.dtstart item.start_time
            entry.dtend   item.end_time || item.start_time + 1.hour
          end

          # The reason for this messy URL helper business is that models can't access the route helpers,
          # and even if they could, they'd need to access the request object so they know what the server's name is and such.
          if item.url.blank?
            entry.url opts[:url_helper].call(item) if opts[:url_helper]
          else
            entry.url item.url
          end

          entry.location item.venue.title if item.venue
          
          # dtstamp and uid added because of a bug in Outlook;
          # Outlook 2003 will not import an .ics file unless it has DTSTAMP, UID, and METHOD
          # use created_at for DTSTAMP; if there's no created_at, use event.start_time;
          entry.dtstamp item.created_at || item.start_time
          entry.uid     "#{opts[:url_helper].call(item)}" if opts[:url_helper]
        end
      end
    end
    
    # Add the calendar name, normalize line-endings to UNIX LF, then replace them with DOS CF-LF.
    return icalendar.
      export.
      sub(/(CALSCALE:\w+)/i, "\\1\nX-WR-CALNAME:#{SETTINGS.name}\nMETHOD:PUBLISH").
      gsub(/\r\n/,"\n").
      gsub(/\n/,"\r\n")
  end

  def location
    venue && venue.location
  end

  def normalize_url!
    unless self.url.blank? || self.url.match(/^[\d\D]+:\/\//)
      self.url = 'http://' + self.url
    end
  end

  # Array of attributes that should be cloned by #to_clone.
  CLONE_ATTRIBUTES = [:title, :description, :venue_id, :url, :tag_list]

  # Return a new record with fields selectively copied from the original, and
  # the start_time and end_time adjusted so that their date is set to today and
  # their time-of-day is set to the original record's time-of-day.
  def to_clone
    clone = self.class.new
    for attribute in CLONE_ATTRIBUTES
      clone.send("#{attribute}=", self.send(attribute))
    end
    if self.start_time
      clone.start_time = self.class._clone_time_for_today(self.start_time)
    end
    if self.end_time
      clone.end_time = self.class._clone_time_for_today(self.end_time)
    end
    return clone
  end

  # Return a time that's today but has the time-of-day component from the
  # +source+ time argument.
  def self._clone_time_for_today(source)
    today = Time.today
    return Time.local(today.year, today.mon, today.day, source.hour, source.min, source.sec, source.usec)
  end

  #---[ Date related ]----------------------------------------------------

  # Returns a range of time spanned by the event.
  def time_range
    if self.start_time && self.end_time
      self.start_time..self.end_time
    elsif self.start_time
      self.start_time..(self.start_time + 1.hour)
    else
      raise ArgumentError, "can't get a time range for an event with no start time"
    end
  end

  # Returns an array of the dates spanned by the event.
  def dates
    if self.start_time && self.end_time
      return (self.start_time.to_date..self.end_time.to_date).to_a
    elsif self.start_time
      return [self.start_time.to_date]
    else
      raise ArgumentError, "can't get dates for an event with no start time"
    end
  end

  # Is this event current? Default cutoff is today
  def current?(cutoff=nil)
    cutoff ||= Time.today
    return (self.end_time || self.start_time) >= cutoff
  end

  # Is this event old? Default cutoff is yesterday
  def old?(cutoff=nil)
    cutoff ||= Time.today # midnight today is the end of yesterday
    return (self.end_time || self.start_time) < cutoff
  end

  # Did this event start before today but ends today or later?
  def ongoing?
    self.start_time < Time.today && self.end_time && self.end_time >= Time.today
  end

  def multiday?
    ( self.dates.size > 1 ) && ( self.duration.seconds > MIN_MULTIDAY_DURATION )
  end

  def duration
    if self.end_time && self.start_time
      return (self.end_time - self.start_time)
    else
      return 0
    end
  end

protected

  def end_time_later_than_start_time
    if start_time && end_time && end_time < start_time
      errors.add(:end_time, "End cannot be before start")
    end
  end
end
