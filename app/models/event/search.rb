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
        Event.search_keywords_grouped_by_currentness(query, order: order, skip_old: current)
      elsif tag
        Event.search_tag_grouped_by_currentness(tag, order: order, current: current)
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
