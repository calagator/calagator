class Event < ActiveRecord::Base
  class Search < Struct.new(:attributes)
    def initialize(*)
      super
      validate!
    end

    def grouped_events
      @grouped_events ||= if query
        Event.search_keywords_grouped_by_currentness(query, order: order, skip_old: current)
      elsif tag
        Event.search_tag_grouped_by_currentness(tag, order: order, current: current)
      end
    end

    def events
      grouped_events[:past] + grouped_events[:current]
    end

    def query
      attributes[:query].presence
    end

    def tag
      attributes[:tag].presence
    end

    def current
      ["1", "true"].include?(attributes[:current])
    end

    def order
      if attributes[:order].presence == "score" && tag
        nil
      else
        attributes[:order].presence
      end
    end

    def failure_message
      @failure_message
    end

    def hard_failure?
      @hard_failure
    end

    private

    def validate!
      unless %w(date name title venue).include?(attributes[:order]) || attributes[:order].blank?
        @failure_message = "Unknown ordering option #{attributes[:order].inspect}, sorting by date instead."
      end

      if attributes[:order].presence == "score" && tag
        @failure_message = "You cannot sort tags by score"
      end

      if !query && !tag
        @failure_message = "You must enter a search query"
        @hard_failure = true
      end

      if query && tag
        # TODO make it possible to search by tag and query simultaneously
        @failure_message = "You can't search by tag and query at the same time"
        @hard_failure = true
      end
    end
  end
end
