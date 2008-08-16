=begin
  Copyright (C) 2008 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

module Vpim
  class Duration
    SECS_HOUR = 60 * 60
    SECS_DAY  = 24 * SECS_HOUR
    MINS_HOUR = 60

    # Initialize from a number of seconds.
    def initialize(secs)
      @secs = secs
    end

    def Duration.secs(secs)
      Duration.new(secs)
    end

    def Duration.mins(mins)
      Duration.new(mins * 60)
    end

    def Duration.hours(hours)
      Duration.new(hours * SECS_HOUR)
    end

    def Duration.days(days)
      Duration.new(days * SECS_DAY)
    end

    def secs
      @secs
    end

    def mins
      (@secs/60).to_i
    end

    def hours
      (@secs/SECS_HOUR).to_i
    end

    def days
      (@secs/SECS_DAY).to_i
    end

    def weeks
      (days/7).to_i
    end

    def by_hours
      [ hours, mins % MINS_HOUR, secs % 60]
    end

    def by_days
      [ days, hours % 24, mins % MINS_HOUR, secs % 60]
    end

    def to_a
      by_days
    end

    def to_s
      Duration.as_str(self.to_a)
    end

    def Duration.as_str(arr)
      s = ""
      case arr.length
        when 4
          if arr[0] > 0
            s << "#{arr[0]} days"
          end
          if arr[1] > 0
            if s.length > 0
              s << ', '
            end
            s << "#{arr[1]} hours"
          end
          if arr[2] > 0
            if s.length > 0
              s << ', '
            end
            s << "#{arr[2]} mins"
          end
          if arr[3] > 0
            if s.length > 0
              s << ', '
            end
            s << "#{arr[3]} secs"
          end
        when 3
          if arr[0] > 0
            s << "#{arr[0]} hours"
          end
          if arr[1] > 0
            if s.length > 0
              s << ', '
            end
            s << "#{arr[1]} mins"
          end
          if arr[2] > 0
            if s.length > 0
              s << ', '
            end
            s << "#{arr[2]} secs"
          end
      end

      s
    end
  end
end

