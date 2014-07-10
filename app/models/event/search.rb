class Event < ActiveRecord::Base
  class Search < Struct.new(:query, :tag, :order, :current)
    def initialize attributes = {}
      members.each do |key|
        send "#{key}=", attributes[key]
      end
      validate!
    end

    def grouped_events
      @grouped_events ||= if query
        self.class.search_keywords_grouped_by_currentness(query, order: order, skip_old: current)
      elsif tag
        self.class.search_tag_grouped_by_currentness(tag, order: order, current: current)
      end
    end

    def current
      ["1", "true"].include?(super)
    end

    def events
      grouped_events[:past] + grouped_events[:current]
    end

    def failure_message
      @failure_message
    end

    def hard_failure?
      @hard_failure
    end

    # Return events matching the given +tag+ are grouped by their currentness,
    # see ::group_by_currentness for data structure details.
    #
    # Will also set :error key if there was a non-fatal problem, e.g. invalid
    # sort order.
    #
    # Options:
    # * :current => Limit results to only current events? Defaults to false.
    def self.search_keywords_grouped_by_currentness(query, opts={})
      events = group_by_currentness(Event.search(query, opts))
      if events[:past] && opts[:order].to_s == "date"
        events[:past].reverse!
      end
      events
    end

    # Return events grouped by their currentness. Accepts the same +args+ as
    # #search. The results hash is keyed by whether the event is current
    # (true/false) and the values are arrays of events.
    def self.search_tag_grouped_by_currentness(tag, opts={})
      result = group_by_currentness(Event.search_tag(tag, opts))
      # TODO Avoid searching for :past results. Currently finding them and discarding them when not wanted.
      result[:past] = [] if opts[:current]
      result
    end

    # Return +events+ grouped by currentness using a data structure like:
    #
    #   {
    #     :current => [ my_current_event, my_other_current_event ],
    #     :past => [ my_past_event ],
    #   }
    def self.group_by_currentness(events)
      grouped = events.group_by(&:current?)
      {:current => grouped[true] || [], :past => grouped[false] || []}
    end

    private

    def validate!
      unless %w(date name title venue score).include?(order) || order.blank?
        @failure_message = "Unknown ordering option #{order.inspect}, sorting by date instead."
      end

      if tag.present? && order == "score"
        @failure_message = "You cannot sort tags by score"
      end

      if [query, tag].all?(&:blank?)
        @failure_message = "You must enter a search query"
        @hard_failure = true
      end

      if [query, tag].all?(&:present?)
        # TODO make it possible to search by tag and query simultaneously
        @failure_message = "You can't search by tag and query at the same time"
        @hard_failure = true
      end
    end
  end
end
