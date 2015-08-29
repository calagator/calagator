module Calagator
  class Event < ActiveRecord::Base
    class Browse < Struct.new(:params, :start_date, :end_date)
      attr_reader :start_time, :end_time

      def events
        scope = Event.non_duplicates.ordered_by_ui_field(params[:order]).includes(:venue, :tags)

        scope = if params[:date]
          scope.within_dates(start_date, end_date)
        else
          scope.future
        end

        if (time = params[:time])
          if (parsed_start_time = Time.zone.parse(time[:start]) and parsed_end_time = Time.zone.parse(time[:end]))
            scope = scope.within_times(parsed_start_time.hour, parsed_end_time.hour)
            @start_time = parsed_start_time.strftime('%I:%M %p')
            @end_time = parsed_end_time.strftime('%I:%M %p')
          elsif (parsed_start_time = Time.zone.parse(time[:start]))
            scope = scope.after_time(parsed_start_time.hour)
            @start_time = parsed_start_time.strftime('%I:%M %p')
          elsif (parsed_end_time = Time.zone.parse(time[:end]))
            scope = scope.before_time(parsed_end_time.hour)
            @end_time = parsed_end_time.strftime('%I:%M %p')
          end
        end

        scope
      end
    end
  end
end
