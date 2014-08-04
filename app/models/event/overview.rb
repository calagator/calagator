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
    def times_to_events
      @times_to_events ||= select_for_overview
    end

    def tags
      @tags ||= Event.tag_counts_on(:tags, limit: 100, conditions: "tags_count >= 10").sort_by(&:name)
    end

    private

    def select_for_overview
      today = Time.zone.now.beginning_of_day
      tomorrow = today + 1.day
      after_tomorrow = tomorrow + 1.day
      future_cutoff = today + 2.weeks

      times_to_events = {
        :today    => [],
        :tomorrow => [],
        :later    => [],
        :more     => nil,
      }

      # Find all events between today and future_cutoff, sorted by start_time
      # includes events any part of which occurs on or after today through on or after future_cutoff
      overview_events = Event.non_duplicates.within_dates(today, future_cutoff)
      overview_events.each do |event|
        if event.start_time < tomorrow
          times_to_events[:today]    << event
        elsif event.start_time >= tomorrow && event.start_time < after_tomorrow
          times_to_events[:tomorrow] << event
        else
          times_to_events[:later]    << event
        end
      end

      # Find next item beyond the future_cuttoff for use in making links to it:
      times_to_events[:more] = Event.after_date(future_cutoff).first

      times_to_events
    end
  end
end

