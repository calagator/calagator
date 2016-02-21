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
  mount_uploader :image, EventImageUploader

  has_paper_trail
  acts_as_taggable

  xss_foliate :strip => [:title], :sanitize => [:description, :venue_details]
  include DecodeHtmlEntitiesHack

  # Associations
  belongs_to :venue, :counter_cache => true
  belongs_to :organization, :counter_cache => true
  belongs_to :source
  belongs_to :parent, foreign_key: :parent_id, class_name: 'Event', inverse_of: :children
  has_many   :children, foreign_key: :parent_id, class_name: 'Event', inverse_of: :parent

  delegate :title, to: :organization, prefix: true, allow_nil: true

  # Validations
  validates_presence_of :title, :start_time, :minimum_age
  validate :end_time_later_than_start_time
  validates_format_of :url,
    :with => /\Ahttps?:\/\/(\w+:?\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?\Z/,
    :allow_blank => true,
    :allow_nil => true

  validates :title, :description, :url, blacklist: true

  validate :valid_rrule

  before_destroy :verify_lock_status

  validates_length_of :title, :url, :rrule, :contact_information, :signup_instructions, maximum: 255

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

  scope :future_with_organization, -> {
    future.order("start_time ASC").non_duplicates.includes(:organization)
  }
  scope :past_with_organization, -> {
    past.order("start_time DESC").non_duplicates.includes(:organization)
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

  def schedule
    IceCube::Schedule.new(start_time, end_time: end_time) do |s|
      s.add_exception_time(start_time)
      s.add_recurrence_rule(rule.until(1.year.from_now)) if rule
    end
  end

  # Don't write "null" or otherwise invalid JSON.
  def rrule=(value)
    if (JSON.parse(value) rescue nil)
      super(value)
    end
  end

  def rule
    RecurringSelect.dirty_hash_to_rule(rrule) if rrule.present?
  end

  # Existing occurrences of this event, excluding self
  def occurrences
    parent_id = self.parent_id || self.id
    self.class.where(parent_id: parent_id).where('id <> ?', id)
  end

  # Future recurrences of this event
  def recurrences
    occurrences.on_or_after_date([start_time, Time.now].compact.max)
  end

  # Update timing of recurrences, creating and destroying events as required
  def update_recurrences
    schedule.all_occurrences.interleave(recurrences)
                            .each do |occurrence, event|
      if occurrence
        event ||= self.class.new
        attrs = attributes.except(:id, :source_id, :duplicate_of_id).merge({
          start_time: occurrence.start_time,
          end_time:   occurrence.end_time,
          parent_id:  parent_id || id
        })
        event.update_attributes(attrs)
      else
        event.destroy
      end
    end
  end

  def has_recurrences?
    recurrences.present?
  end
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

  def url=(value)
    super UrlPrefixer.prefix(value)
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

  def lock_editing!
    update_attribute(:locked, true)
  end

  def unlock_editing!
    update_attribute(:locked, false)
  end

  #---[ Queries ]---------------------------------------------------------

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

  def location
    venue && venue.location
  end

  def venue_title
    venue && venue.title
  end

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

  def duration
    if end_time && start_time
      (end_time - start_time)
    else
      0
    end
  end

  def start_date
      start_time.to_date
  end

protected

  def end_time_later_than_start_time
    if start_time && end_time && end_time < start_time
      errors.add(:end_time, "cannot be before start")
    end
  end

  def verify_lock_status
    return !locked
  end

  def valid_rrule
    if rrule.present?
      begin
        valid = RecurringSelect.is_valid_rule?(JSON.parse(rrule))
      rescue
        valid = false
      end
      errors.add(:rrule, "Must be a valid reccurrence rule.") unless valid
    end
  end
end
