=begin
  Copyright (C) 2008 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

require 'date'

# Extensions to builtin Time allowing addition to Time by multiples of other
# intervals than a second.

class Time
    # Returns a new Time, +years+ later than this time. Feb 29 of a
    # leap year will be rounded up to Mar 1 if the target date is not a leap
    # year.
    def plus_year(years)
      Time.local(year + years, month, day, hour, min, sec, usec)
    end

    # Returns a new Time, +months+ later than this time. The day will be
    # rounded down if it is not valid for that month.
    # Jan 31 plus 1 month will be on Feb 28!
    def plus_month(months)
      d = Date.new(year, month, day)
      d >>= months
      Time.local(d.year, d.month, d.day, hour, min, sec, usec)
    end

    # Returns a new Time, +days+ later than this time.
    # Does this do as I expect over DST? What if the hour doesn't exist
    # in the next day, due to DST changes?
    def plus_day(days)
      d = Date.new(year, month, day)
      d += days
      Time.local(d.year, d.month, d.day, hour, min, sec, usec)
    end
end

