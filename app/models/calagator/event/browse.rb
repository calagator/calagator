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
          scope = scope.within_times(parsed_start_time.hour, parsed_end_time.hour)
        elsif parsed_start_time
          scope = scope.after_time(parsed_start_time.hour)
        elsif parsed_end_time
          scope = scope.before_time(parsed_end_time.hour)
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
    end
  end
end
