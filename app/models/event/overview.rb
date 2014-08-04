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
      times_to_events[:today]
    end

    def tomorrow
      times_to_events[:tomorrow]
    end

    def later
      times_to_events[:later]
    end

    def more
      times_to_events[:more]
    end

    def tags
      @tags ||= Event.tag_counts_on(:tags, limit: 100, conditions: "tags_count >= 10").sort_by(&:name)
    end

    private

    def times_to_events
      @times_to_events ||= select_for_overview
    end

    def select_for_overview
      times_to_events = {
        :today    => [],
        :tomorrow => [],
        :later    => [],
        :more     => nil,
      }

      # Find all events between today and future_cutoff, sorted by start_time
      # includes events any part of which occurs on or after today through on or after future_cutoff
      overview_events = Event.non_duplicates.within_dates(today_date, future_cutoff_date)
      overview_events.each do |event|
        if event.start_time < tomorrow_date
          times_to_events[:today]    << event
        elsif event.start_time >= tomorrow_date && event.start_time < after_tomorrow_date
          times_to_events[:tomorrow] << event
        else
          times_to_events[:later]    << event
        end
      end

      # Find next item beyond the future_cuttoff for use in making links to it:
      times_to_events[:more] = Event.after_date(future_cutoff_date).first

      times_to_events
    end

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

