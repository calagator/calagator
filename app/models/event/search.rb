class Event < ActiveRecord::Base
  class Search < Struct.new(:query, :tag, :order, :current)
    def initialize attributes = {}
      members.each do |key|
        send "#{key}=", attributes[key]
      end
      validate!
    end

    # Return +events+ grouped by currentness using a data structure like:
    #
    #   {
    #     :current => [ my_current_event, my_other_current_event ],
    #     :past => [ my_past_event ],
    #   }
    def grouped_events
      @grouped_events ||= begin
        events = if query
          Event.search(query, order: order, skip_old: current)
        elsif tag
          Event.search_tag(tag, order: order, current: current)
        end
        grouped_events = self.class.group_by_currentness(events)
        grouped_events[:past].reverse! if grouped_events[:past] && order.to_s == "date"
        grouped_events[:past] = [] if current
        grouped_events
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
