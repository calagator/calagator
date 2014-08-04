class Event < ActiveRecord::Base
  class Overview
    def times_to_events
      @times_to_events ||= Event.select_for_overview
    end

    def tags
      @tags ||= Event.tag_counts_on(:tags, limit: 100, conditions: "tags_count >= 10").sort_by(&:name)
    end
  end
end

