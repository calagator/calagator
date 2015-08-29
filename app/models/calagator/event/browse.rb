module Calagator
  class Event < ActiveRecord::Base
    class Browse < Struct.new(:params)
      def events
        order.filter_by_date.filter_by_time.scope
      end

      def start_date
        date_for(:start) || Time.zone.today
      end

      def end_date
        date_for(:end) || Time.zone.today + 3.months
      end

      def start_time
        time_for(:start).strftime('%I:%M %p') if time_for(:start)
      end

      def end_time
        time_for(:end).strftime('%I:%M %p') if time_for(:end)
      end

      def errors
        @errors ||= []
      end

      protected

      def scope
        @scope ||= Event.non_duplicates.includes(:venue, :tags)
      end

      def order
        @scope = scope.ordered_by_ui_field(params[:order])
        self
      end

      def filter_by_date
        @scope = if params[:date]
          scope.within_dates(start_date, end_date)
        else
          scope.future
        end
        self
      end

      def filter_by_time
        if time_for(:start) && time_for(:end)
          @scope = within_times(scope, time_for(:start), time_for(:end))
        elsif time_for(:start)
          @scope = after_time(scope, time_for(:start))
        elsif time_for(:end)
          @scope = before_time(scope, time_for(:end))
        end
        self
      end

      private

      def date_for(kind)
        return unless params[:date].present?
        Date.parse(params[:date][kind])
      rescue NoMethodError, ArgumentError, TypeError
        errors << "Can't filter by an invalid #{kind} date."
        nil
      end

      def time_for(kind)
        Time.zone.parse(params[:time][kind]) rescue nil
      end

      def within_times(scope, start_time, end_time)
        scope.order(:start_time).select do |event|
          event.start_time.hour > start_time.hour && event.end_time.hour < end_time.hour
        end
      end

      def before_time(scope, end_time)
        scope.order(:end_time).select do |event|
          event.end_time.hour < end_time.hour
        end
      end

      def after_time(scope, start_time)
        scope.order(:start_time).select do |event|
          event.start_time.hour >= start_time.hour
        end
      end
    end
  end
end
