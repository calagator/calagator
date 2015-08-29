module Calagator
  class Event < ActiveRecord::Base
    class Browse < Struct.new(:params, :start_date, :end_date)
      def events
        scope = Event.non_duplicates.ordered_by_ui_field(params[:order]).includes(:venue, :tags)

        scope = if params[:date]
          scope.within_dates(start_date, end_date)
        else
          scope.future
        end

        if parsed_start_time && parsed_end_time
          scope = within_times(scope, parsed_start_time.hour, parsed_end_time.hour)
        elsif parsed_start_time
          scope = after_time(scope, parsed_start_time.hour)
        elsif parsed_end_time
          scope = before_time(scope, parsed_end_time.hour)
        end

        scope
      end

      def start_time
        parsed_start_time.strftime('%I:%M %p') if parsed_start_time
      end

      def end_time
        parsed_end_time.strftime('%I:%M %p') if parsed_end_time
      end

      private

      def parsed_start_time
        Time.zone.parse(params[:time][:start]) rescue nil
      end

      def parsed_end_time
        Time.zone.parse(params[:time][:end]) rescue nil
      end

      def within_times(scope, start_time, end_time)
        scope.order(:start_time).select do |rec|
          rec.start_time.hour > start_time && rec.end_time.hour < end_time
        end
      end

      def before_time(scope, end_time)
        scope.order(:end_time).select do |rec|
          rec.end_time.hour < end_time
        end
      end

      def after_time(scope, start_time)
        scope.order(:start_time).select do |rec|
          rec.start_time.hour >= start_time
        end
      end
    end
  end
end
