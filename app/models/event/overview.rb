class Event < ActiveRecord::Base
  class Overview
    def initialize(base_scope=Event)
      @base_scope = base_scope
    end

    def today
      @base_scope.non_duplicates.within_dates(today_date, tomorrow_date)
    end

    def tomorrow
      @base_scope.non_duplicates.within_dates(tomorrow_date, after_tomorrow_date)
    end

    def later
      @base_scope.non_duplicates.within_dates(after_tomorrow_date, future_cutoff_date)
    end

    def more
      @base_scope.after_date(future_cutoff_date).first
    end

    def tags
      @tags ||= @base_scope.tag_counts_on(:tags, limit: 100, conditions: "tags_count >= 10").sort_by(&:name)
    end

    private

    def today_date
      @today_date ||= Time.zone.now.beginning_of_day
    end

    def tomorrow_date
      today_date + 1.day
    end

    def after_tomorrow_date
      tomorrow_date + 1.day
    end

    def future_cutoff_date
      today_date + 2.weeks
    end
  end
end

