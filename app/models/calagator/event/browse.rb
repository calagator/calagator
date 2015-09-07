module Calagator
  class Event < ActiveRecord::Base
    class Browse < Struct.new(:order, :date, :time)
      def initialize(attributes={})
        members.each do |key|
          send "#{key}=", attributes[key]
        end
      end

      def events
        @events ||= sort.filter_by_date.filter_by_time.scope
      end

      def start_date
        date_for(:start).strftime('%Y-%m-%d')
      end

      def end_date
        date_for(:end).strftime('%Y-%m-%d')
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

      def default?
        values.all?(&:blank?)
      end

      protected

      def scope
        @scope ||= Event.non_duplicates.includes(:venue, :tags)
      end

      def sort
        @scope = scope.ordered_by_ui_field(order)
        self
      end

      def filter_by_date
        @scope = if date
          scope.within_dates(date_for(:start), date_for(:end))
        else
          scope.future
        end
        self
      end

      def filter_by_time
        @scope = after_time if time_for(:start)
        @scope = before_time if time_for(:end)
        self
      end

      private

      def default_date_for(kind)
        kind == :start ? Time.zone.today : Time.zone.today + 3.months
      end

      def date_for(kind)
        return default_date_for(kind) unless date.present?
        Date.parse(date[kind])
      rescue NoMethodError, ArgumentError, TypeError
        errors << "Can't filter by an invalid #{kind} date."
        default_date_for(kind)
      end

      def time_for(kind)
        Time.zone.parse(time[kind]) rescue nil
      end

      def before_time
        scope.select { |event| event.end_time.hour <= time_for(:end).hour }
      end

      def after_time
        scope.select { |event| event.start_time.hour >= time_for(:start).hour }
      end
    end
  end
end
