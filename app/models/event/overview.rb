class Event < ActiveRecord::Base
  class Overview
    # Returns groups of records for the site overview screen in the following format:
    #
    #   {
    #     :today => [...],    # Events happening today or empty array
    #     :tomorrow => [...], # Events happening tomorrow or empty array
    #     :later => [...],    # Events happening within two weeks or empty array
    #     :more => ...,       # First event after the two week window or nil
    #   }
    def today
      Event.non_duplicates.within_dates(today_date, tomorrow_date)
    end

    def tomorrow
      Event.non_duplicates.within_dates(tomorrow_date, after_tomorrow_date)
    end

    def later
      Event.non_duplicates.within_dates(after_tomorrow_date, future_cutoff_date)
    end

    def more
      Event.after_date(future_cutoff_date).first
    end

    def tags
      @tags ||= Event.tag_counts_on(:tags, limit: 100, conditions: "tags_count >= 10").sort_by(&:name)
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

