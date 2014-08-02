# == Schema Information
# Schema version: 20110604174521
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
#  version         :integer
#  rrule           :string(255)
#  venue_details   :text
#

# == Event
#
# A model representing a calendar event.
class Event < ActiveRecord::Base
  # Treat any event with a duration of at least this many hours as a multiday
  # event. This constant is used by the #multiday? method and is primarily
  # meant to make iCalendar exports display this event as covering a range of
  # days, rather than hours.
  MIN_MULTIDAY_DURATION = 20.hours

  has_paper_trail
  acts_as_taggable

  xss_foliate :strip => [:title], :sanitize => [:description, :venue_details]
  include DecodeHtmlEntitiesHack

  # Associations
  belongs_to :venue, :counter_cache => true
  belongs_to :source

  # Triggers
  before_validation :normalize_url!

  # Validations
  validates_presence_of :title, :start_time
  validate :end_time_later_than_start_time
  validates_format_of :url,
    :with => /\Ahttps?:\/\/(\w+:?\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?\Z/,
    :allow_blank => true,
    :allow_nil => true

  include ValidatesBlacklistOnMixin
  validates_blacklist_on :title, :description, :url

  # Duplicates
  include DuplicateChecking
  duplicate_checking_ignores_attributes    :source_id, :version, :venue_id
  duplicate_squashing_ignores_associations :tags, :base_tags, :taggings

  # Named scopes
  scope :after_date, lambda { |date|
    where(["start_time >= ?", date]).order(:start_time)
  }
  scope :on_or_after_date, lambda { |date|
    time = date.beginning_of_day
    where("(start_time >= :time) OR (end_time IS NOT NULL AND end_time > :time)",
      :time => time).order(:start_time)
  }
  scope :before_date, lambda { |date|
    time = date.beginning_of_day
    where("start_time < :time", :time => time).order(:start_time)
  }
  scope :future, lambda { on_or_after_date(Time.zone.today) }
  scope :past, lambda { before_date(Time.zone.today) }
  scope :within_dates, lambda { |start_date, end_date|
    if start_date == end_date
      end_date = end_date + 1.day
    end
    on_or_after_date(start_date).before_date(end_date)
  }

  scope :future_with_venue, -> {
    future.order("start_time ASC").non_duplicates.includes(:venue)
  }
  scope :past_with_venue, -> {
    past.order("start_time DESC").non_duplicates.includes(:venue)
  }

  # Expand the simple sort order names from the URL into more intelligent SQL order strings
  scope :ordered_by_ui_field, lambda{|ui_field|
    case ui_field
      when 'name'
        order('lower(events.title), start_time')
      when 'venue'
        includes(:venue).order('lower(venues.title), start_time')
      else # when 'date', nil
        order('start_time')
    end
  }

  #---[ Overrides ]-------------------------------------------------------

  # Return the title but strip out any whitespace.
  def title
    # TODO Generalize this code so we can use it on other attributes in the different model classes. The solution should use an #alias_method_chain to make sure it's not breaking any explicit overrides for an attribute.
    read_attribute(:title).to_s.strip
  end

  # Return description without those pesky carriage-returns.
  def description
    # TODO Generalize this code so we can reuse it on other attributes.
    read_attribute(:description).to_s.gsub("\r\n", "\n").gsub("\r", "\n")
  end

  # Set the start_time to the given +value+, which could be a Time, Date,
  # DateTime, String, Array of Strings, or nil.
  def start_time=(value)
    super time_for(value)
  rescue ArgumentError
    errors.add :start_time, "is invalid"
    super nil
  end

  # Set the end_time to the given +value+, which could be a Time, Date,
  # DateTime, String, Array of Strings, or nil.
  def end_time=(value)
    super time_for(value)
  rescue ArgumentError
    errors.add :end_time, "is invalid"
    super nil
  end

  def time_for(value)
    value = value.join(' ') if value.kind_of?(Array)
    value = Time.zone.parse(value) if value.kind_of?(String) # this will throw ArgumentError if invalid
    value
  end
  private :time_for

  #---[ Queries ]---------------------------------------------------------

  # Associate this event with the +venue+. The +venue+ can be given as a Venue
  # instance, an ID, or a title.
  def associate_with_venue(venue_identifier)
    new_venue = Venue.find_by_identifier(venue_identifier)
    self.venue = new_venue && new_venue.progenitor
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
    today = Time.zone.now.beginning_of_day
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
    overview_events = non_duplicates.within_dates(today, future_cutoff)
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
    times_to_events[:more] = Event.after_date(future_cutoff).first

    times_to_events
  end

  # Return Hash of Events grouped by the +type+.
  def self.find_duplicates_by_type(type='na')
    case type.to_s.strip
    when 'na', ''
      { [] => future }
    else
      kind = %w[all any].include?(type) ? type.to_sym : type.split(',').map(&:to_sym)
      find_duplicates_by(kind,
        :grouped => true,
        :where => "a.start_time >= #{connection.quote(Time.now - 1.day)}")
    end
  end

  #---[ Searching ]-------------------------------------------------------

  # NOTE: The `Event.search` method is implemented elsewhere! For example, it's
  # added by SearchEngine::ActsAsSolr if you're using that search engine.

  def self.search_tag(tag, opts={})
    includes(:venue).tagged_with(tag).ordered_by_ui_field(opts[:order])
  end

  def self.search(query, opts={})
    SearchEngine.search(query, opts)
  end

  #---[ Transformations ]-------------------------------------------------

  # Returns an Event created from an AbstractEvent.
  def self.from_abstract_event(abstract_event, source=nil)
    event = Event.new

    event.source       = source
    event.title        = abstract_event.title
    event.description  = abstract_event.description
    event.start_time   = abstract_event.start_time.blank? ? nil : Time.parse(abstract_event.start_time.to_s)
    event.end_time     = abstract_event.end_time.blank? ? nil : Time.parse(abstract_event.end_time.to_s)
    event.url          = abstract_event.url
    event.venue        = Venue.from_abstract_location(abstract_event.location, source) if abstract_event.location
    event.tag_list     = abstract_event.tags.join(',')

    duplicates = event.find_exact_duplicates
    event = duplicates.first.progenitor if duplicates
    event
  end

  # Returns an hCalendar string representing this Event.
  def to_hcal
    <<-EOF
<div class="vevent">
<a class="url" href="#{url}">#{url}</a>
<span class="summary">#{title}</span>:
<abbr class="dtstart" title="#{start_time.to_s(:yyyymmdd)}">#{start_time.to_s(:long_date).gsub(/\b[0](\d)/, '\1')}</abbr>,
at the <span class="location">#{venue_title}</span>
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
      calendar.prodid = "-//Calagator//EN"
      events.each do |item|
        calendar.event do |entry|
          entry.summary(item.title || 'Untitled Event')

          desc = String.new.tap do |d|
            if item.multiday?
              d << "This event runs from #{TimeRange.new(item.start_time, item.end_time, :format => :text).to_s}."
              d << "\n\n Description:\n"
            end

            d << Loofah::Helpers::strip_tags(item.description) if item.description.present?
            d << "\n\nTags: #{item.tag_list}" unless item.tag_list.blank?
            d << "\n\nImported from: #{opts[:url_helper].call(item)}" if opts[:url_helper]
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

          if item.url.present?
            entry.url item.url
          end

          if item.venue
            entry.location [item.venue_title, item.venue.full_address].compact.join(": ")
          end

          # dtstamp and uid added because of a bug in Outlook;
          # Outlook 2003 will not import an .ics file unless it has DTSTAMP, UID, and METHOD
          # use created_at for DTSTAMP; if there's no created_at, use event.start_time;
          entry.dtstamp item.created_at || item.start_time
          entry.uid     "#{opts[:url_helper].call(item)}" if opts[:url_helper]
        end
      end
    end

    # Add the calendar name, normalize line-endings to UNIX LF, then replace them with DOS CF-LF.
    icalendar.
      export.
      sub(/(CALSCALE:\w+)/i, "\\1\nX-WR-CALNAME:#{SETTINGS.name}\nMETHOD:PUBLISH").
      gsub(/\r\n/,"\n").
      gsub(/\n/,"\r\n")
  end

  def location
    venue && venue.location
  end

  def venue_title
    venue && venue.title
  end

  def normalize_url!
    unless url.blank? || url.match(/^[\d\D]+:\/\//)
      self.url = 'http://' + url
    end
  end

  # Array of attributes that should be cloned by #to_clone.
  CLONE_ATTRIBUTES = [:title, :description, :venue_id, :url, :tag_list, :venue_details]

  # Return a new record with fields selectively copied from the original, and
  # the start_time and end_time adjusted so that their date is set to today and
  # their time-of-day is set to the original record's time-of-day.
  def to_clone
    clone = self.class.new
    CLONE_ATTRIBUTES.each do |attribute|
      clone.send("#{attribute}=", send(attribute))
    end
    if start_time
      clone.start_time = clone_time_for_today(start_time)
    end
    if end_time
      clone.end_time = clone_time_for_today(end_time)
    end
    clone
  end

  # Return a time that's today but has the time-of-day component from the
  # +source+ time argument.
  def clone_time_for_today(source)
    today = Date.today
    Time.local(today.year, today.mon, today.day, source.hour, source.min, source.sec, source.usec)
  end
  private :clone_time_for_today

  #---[ Date related ]----------------------------------------------------

  # Returns an array of the dates spanned by the event.
  def dates
    raise ArgumentError, "can't get dates for an event with no start time" unless start_time
    if end_time
      (start_time.to_date..end_time.to_date).to_a
    else
      [start_time.to_date]
    end
  end

  # Is this event current?
  def current?
    (end_time || start_time) >= Date.today.to_time
  end

  # Is this event old?
  def old?
    (end_time || start_time + 1.hour) <= Time.zone.now.beginning_of_day
  end

  # Did this event start before today but ends today or later?
  def ongoing?
    start_time < Date.today.to_time && end_time && end_time >= Date.today.to_time
  end

  def multiday?
    ( dates.size > 1 ) && ( duration.seconds > MIN_MULTIDAY_DURATION )
  end

  def duration
    if end_time && start_time
      (end_time - start_time)
    else
      0
    end
  end

protected

  def end_time_later_than_start_time
    if start_time && end_time && end_time < start_time
      errors.add(:end_time, "cannot be before start")
    end
  end
end
