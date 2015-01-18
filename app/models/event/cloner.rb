# Return a new record with fields selectively copied from the original, and
# the start_time and end_time adjusted so that their date is set to today and
# their time-of-day is set to the original record's time-of-day.
class Event < ActiveRecord::Base
  class Cloner < Struct.new(:event)
    def self.clone(event)
      new(event).clone
    end

    ATTRIBUTES = [:title, :description, :venue_id, :url, :tag_list, :venue_details]

    def clone
      clone = Event.new
      ATTRIBUTES.each do |attribute|
        clone.send "#{attribute}=", event.send(attribute)
      end
      if event.start_time
        clone.start_time = clone_time_for_today(event.start_time)
      end
      if event.end_time
        clone.end_time = clone_time_for_today(event.end_time)
      end
      clone
    end

    private

    # Return a time that's today but has the time-of-day component from the
    # +source+ time argument.
    def clone_time_for_today(source)
      today = Date.today
      Time.local(today.year, today.mon, today.day, source.hour, source.min, source.sec, source.usec)
    end
  end
end

