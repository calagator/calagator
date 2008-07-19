=begin
  Copyright (C) 2006 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

module Vpim
  class Icalendar
    module Property

      # Occurrences are calculated from DTSTART: and RRULE:. If there is not
      # RRULE:, the component recurs only once, at the start time.
      #
      # Limitations:
      #
      # Only a single RRULE: is currently supported, this is the most common
      # case.
      #
      # Implementation of multiple RRULE:s, and RDATE:, EXRULE:, and EXDATE: is
      # on the todo list.  Its not a very high priority, because I haven't seen
      # calendars using the full range of recurrence features, and haven't
      # received feedback from any users requesting these features. So, if you
      # need it, contact me and implementation will get on the schedule.
      module Recurrence
        # The times this event occurs, as a Vpim::Rrule.
        def occurences
          start = dtstart
          unless start
            raise ArgumentError, "Components with no DTSTART: don't have occurences!"
          end
          Vpim::Rrule.new(start, propvalue('RRULE'))
        end

        # Check if this event overlaps with the time period later than or equal to +t0+, but
        # earlier than +t1+.
        def occurs_in?(t0, t1)
          occurences.each_until(t1).detect { |t| tend = t + (duration || 0); tend > t0 }
        end

      end
    end
  end
end


