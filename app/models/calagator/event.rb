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

require "calagator/blacklist_validator"
require "calagator/duplicate_checking"
require "calagator/decode_html_entities_hack"
require "calagator/strip_whitespace"
require "calagator/url_prefixer"
require "paper_trail"
require "loofah-activerecord"
require "loofah/activerecord/xss_foliate"
require "active_model/sequential_validator"
require "validate_url"

# == Event
#
# A model representing a calendar event.

module Calagator
class Event < ActiveRecord::Base
  self.table_name = "events"

  has_paper_trail
  acts_as_taggable

  xss_foliate strip: [:title, :description, :venue_details]

  include DecodeHtmlEntitiesHack

  # Associations
  belongs_to :venue, :counter_cache => true
  belongs_to :source

  # Validations
  validates :title, :description, :url, blacklist: true
  validates :start_time, :end_time, sequential: true
  validates :title, :start_time, presence: true
  validates :url, url: { allow_blank: true }

  # Duplicates
  include DuplicateChecking
  duplicate_checking_ignores_attributes    :source_id, :version, :venue_id
  duplicate_squashing_ignores_associations :tags, :base_tags, :taggings
  duplicate_finding_scope -> { future.order(:id) }

  extend Finders
  #---[ Overrides ]-------------------------------------------------------

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
    value = value.to_s if value.kind_of?(Date)
    value = Time.zone.parse(value) if value.kind_of?(String) # this will throw ArgumentError if invalid
    value
  end
  private :time_for

  #---[ Lock toggling ]---------------------------------------------------

  def lock_editing!
    update_attribute(:locked, true)
  end

  def unlock_editing!
    update_attribute(:locked, false)
  end

  before_destroy { !locked } # prevent locked events from being destroyed

  #---[ Date related ]----------------------------------------------------

  def current?
    (end_time || start_time) >= Date.today.to_time
  end

  def old?
    (end_time || start_time + 1.hour) <= Time.zone.now.beginning_of_day
  end

  def ongoing?
    return unless end_time && start_time
    (start_time..end_time).cover?(Date.today.to_time)
  end

  def duration
    return 0 unless end_time && start_time
    (end_time - start_time)
  end
end

end
