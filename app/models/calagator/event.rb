# frozen_string_literal: true

# == Schema Information
#
# Table name: events
#
#  id              :integer          not null, primary key
#  description     :text
#  end_time        :datetime
#  locked          :boolean          default(FALSE)
#  rrule           :string
#  start_time      :datetime
#  title           :string
#  url             :string
#  venue_details   :text
#  created_at      :datetime
#  updated_at      :datetime
#  duplicate_of_id :integer
#  source_id       :integer
#  venue_id        :integer
#

require 'calagator/denylist_validator'
require 'calagator/duplicate_checking'
require 'calagator/decode_html_entities_hack'
require 'calagator/strip_whitespace'
require 'calagator/url_prefixer'
require 'paper_trail'
require 'loofah-activerecord'
require 'loofah/activerecord/xss_foliate'
require 'active_model/sequential_validator'
require 'active_model/serializers/xml'

# == Event
#
# A model representing a calendar event.

module Calagator
  class Event < ApplicationRecord
    self.table_name = 'events'
    self.belongs_to_required_by_default = false

    has_paper_trail
    acts_as_taggable_on :tags

    xss_foliate strip: %i[title description venue_details]

    include DecodeHtmlEntitiesHack
    include ActiveModel::Serializers::Xml

    # Associations
    belongs_to :venue, counter_cache: true
    belongs_to :source

    # Validations
    validates :title, :description, :url, denylist: true
    validates :start_time, :end_time, sequential: true
    validates :title, :start_time, presence: true
    validates :url,
              format: { with: %r{\Ahttps?://(\w+:?\w*@)?(\S+)(:[0-9]+)?(/|/([\w#!:.?+=&%@!\-/]))?\Z},
                        allow_blank: true }

    before_destroy :check_if_locked_before_destroy # prevent locked events from being destroyed

    # Duplicates
    include DuplicateChecking
    duplicate_checking_ignores_attributes    :source_id, :version, :venue_id, :tag_list
    duplicate_squashing_ignores_associations :tags, :base_tags, :taggings
    duplicate_finding_scope -> { future.order(:id) }
    after_squashing_duplicates ->(primary) { primary.venue.try(:update_events_count!) }

    # Named scopes
    scope :after_date, lambda { |date|
      where(['start_time >= ?', date]).order(:start_time)
    }
    scope :on_or_after_date, lambda { |date|
      time = date.beginning_of_day
      where('(events.start_time >= :time) OR (events.end_time IS NOT NULL AND events.end_time > :time)',
            time: time).order(:start_time)
    }
    scope :before_date, lambda { |date|
      time = date.beginning_of_day
      where('start_time < :time', time: time).order(start_time: :desc)
    }
    scope :future, -> { on_or_after_date(Time.zone.today) }
    scope :past, -> { before_date(Time.zone.today) }
    scope :within_dates, lambda { |start_date, end_date|
      end_date += 1.day if start_date == end_date
      on_or_after_date(start_date).before_date(end_date)
    }

    # Expand the simple sort order names from the URL into more intelligent SQL order strings
    scope :ordered_by_ui_field, lambda { |ui_field|
      scope = case ui_field
              when 'name'
                order(Arel.sql('lower(events.title)'))
              when 'venue'
                includes(:venue).order(Arel.sql('lower(venues.title)')).references(:venues)
              else
                all
      end
      scope.order('start_time')
    }

    #---[ Overrides ]-------------------------------------------------------

    def url=(value)
      super UrlPrefixer.prefix(value)
    end

    # Set the start_time to the given +value+, which could be a Time, Date,
    # DateTime, String, Array of Strings, or nil.
    def start_time=(value)
      super time_for(value)
    rescue ArgumentError
      errors.add :start_time, 'is invalid'
      super nil
    end

    # Set the end_time to the given +value+, which could be a Time, Date,
    # DateTime, String, Array of Strings, or nil.
    def end_time=(value)
      super time_for(value)
    rescue ArgumentError
      errors.add :end_time, 'is invalid'
      super nil
    end

    def time_for(value)
      value = value.to_s if value.is_a?(Date)
      if value.is_a?(String)
        value = Time.zone.parse(value)
      end # this will throw ArgumentError if invalid
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

    def check_if_locked_before_destroy
      return if !locked
      errors.add :base, "Event must be unlocked before destroying"
      throw(:abort)
    end

    #---[ Searching ]-------------------------------------------------------

    def self.search_tag(tag, opts = {})
      includes(:venue).tagged_with(tag).ordered_by_ui_field(opts[:order])
    end

    def self.search(query, opts = {})
      SearchEngine.search(query, opts)
    end

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
