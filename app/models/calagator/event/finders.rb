module Calagator
  class Event < ActiveRecord::Base
    module Finders
      def after_date(date)
        where(["start_time >= ?", date]).order(:start_time)
      end

      def on_or_after_date(date)
        time = date.beginning_of_day
        where("(events.start_time >= :time) OR (events.end_time IS NOT NULL AND events.end_time > :time)",
          time: time).order(:start_time)
      end

      def before_date(date)
        time = date.beginning_of_day
        where("start_time < :time", time: time).order(start_time: :desc)
      end

      def future
        on_or_after_date(Time.zone.today)
      end

      def past
        before_date(Time.zone.today)
      end

      def within_dates(start_date, end_date)
        if start_date == end_date
          end_date = end_date + 1.day
        end
        on_or_after_date(start_date).before_date(end_date)
      end

      # Expand the simple sort order names from the URL into more intelligent SQL order strings
      def ordered_by_ui_field(ui_field)
        scope = case ui_field
        when 'name'
          order('lower(events.title)')
        when 'venue'
          includes(:venue).order('lower(venues.title)').references(:venues)
        else
          all
        end
        scope.order('start_time')
      end

      def search_tag(tag, opts={})
        includes(:venue).tagged_with(tag).ordered_by_ui_field(opts[:order])
      end

      def search(query, opts={})
        SearchEngine.search(query, opts)
      end
    end
  end
end
