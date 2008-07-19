=begin
  Copyright (C) 2006 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

require 'vpim/rfc2425'
require 'vpim/date'
require 'vpim/time'
require 'vpim/vpim'

=begin
require 'pp'

$debug = ENV['DEBUG']

def debug(*objs)
  if $debug
    pp(*objs)
    print '  (', caller(1)[0], ')', "\n"
  end
end
=end

module Vpim

  # Implements the iCalendar recurence rule syntax. See etc/rrule.txt for the
  # syntax description and examples from RFC 2445. The description is pretty
  # hard to understand, but the examples are more helpful.
  #
  # The implementation is pretty complete, but still lacks support for:
  #
  # TODO - BYWEEKLY, BYWEEKNO, WKST: rules that recur by the week, or are
  # limited to particular weeks, not hard, but not trivial, I'll do it for the
  # next release
  #
  # TODO - BYHOUR, BYMINUTE, BYSECOND: trivial to do, but I don't have an
  # immediate need for them, I'll do it for the next release
  #
  # TODO - BYSETPOS: limiting to only certain recurrences in a set (what does
  # -1, last occurence, mean for an infinitely occuring rule?)
  #
  # TODO - new API? -> Rrule#infinite?
  #
  # == Examples
  #
  # - link:rrule.txt: utility for printing recurrence rules
  class Rrule
    include Enumerable

    # The recurrence rule, +rrule+, specifies how to generate a set of times
    # from a start time, +dtstart+ (which must the first of the set of
    # recurring times). If +rrule+ is nil, the set contains only +dtstart+.
    def initialize(dtstart, rrule = nil)
      # dtstart must be in local time, they say, but I think that really
      # means must be in a particular timezone

      # Note: DTSTART is always in the recurrence set
       @dtstart = dtstart
       @rrule = rrule

       # Freq is mandatory, but must occur only once.
       @freq = nil
   
       # Both Until and Count must not occur, neither is OK.
       @until = nil
       @count = nil
   
       # Interval is optional, but defaults to 1.
       @interval = 1

       # WKST defines what day a week begins on, the default is monday.
       @wkst = 'MO'
   
       # Recurrence can modified by these.
       @by = {}
  
       if @rrule
         @rrule.scan(/([^;=]+)=([^;=]+)/) do |key,value|
           key.upcase!
           value.upcase!

           case key
           when 'FREQ'
             @freq = value

           when 'UNTIL'
             if @count
               raise "found UNTIL, but COUNT already specified"
             end
             @until = Rrule.time_from_rfc2425(value)

           when 'COUNT'
             if @until
               raise "found COUNT, but UNTIL already specified"
             end
             @count = value.to_i

           when 'INTERVAL'
             @interval = value.to_i
             if @interval < 1
               raise "interval must be a positive integer"
             end

           when 'WKST'
             # TODO - check value is MO-SU
             @wkst = value

           else
             @by[key] = value
           end
         end

         if !@freq
           # TODO - this shouldn't be an arg error, but a FormatError, its not the
           # caller's fault!
           raise ArgumentError, "recurrence rule lacks a frequency"
         end
       end
    end

    # Return an Enumerable, it's #each() will yield over all occurences up to
    # (and not including) time +dountil+.
    def each_until(dountil)
      Vpim::Enumerator.new(self, dountil)
    end

    # Yields for each +ytime+ in the recurring set of events.
    #
    # Warning: the set may be infinite! If you need an upper bound on the
    # number of occurences, you need to implement a count, or pass a time,
    # +dountil+, which will not be iterated past (i.e. all times yielded will be
    # less than +dountil+).
    #
    # Also, iteration will not currently continue past the limit of a Time
    # object, which is some time in 2037 with the 32-bit time_t common on
    # most systems.
    def each(dountil = nil) #:yield: ytime
      t = @dtstart.clone
      count = 1

      # Time.to_a => [ sec, min, hour, day, month, year, wday, yday, isdst, zone ]

      # Every event occurs at least once, at its start time, but only if the start
      # time is earlier than DOUNTIL...
      if !@rrule
        if !dountil || t < dountil
          yield t
        end
        return self
      end

      loop do
        # Build the set of times to yield within this interval (and after
        # DTSTART)

        days  = DaySet.new(t)
        hour  = nil
        min   = nil
        sec   = nil

        # Need to make a Dates class, and make month an instance of it, and add
        # the "intersect" operator.

        case @freq
          #when 'YEARLY' then
          # Don't need to keep track of year, all occurences are within t's
          # year.
          when 'MONTHLY'  then  days.month = t.month #month = { t.month => nil }
  #       when 'WEEKLY'   then  days.mday = t.month, t.mday
          # TODO - WEEKLY
          when 'DAILY'    then  days.mday = t.month, t.mday #month = { t.month => [ t.mday ] }
          when 'HOURLY'   then  hour  = [t.hour]
          when 'MINUTELY' then  min   = [t.min]
          when 'SECONDLY' then  sec   = [t.sec]
        end

        # Process the BY* modifiers in RFC defined order:
        #  BYMONTH, BYWEEKNO, BYYEARDAY, BYMONTHDAY, BYDAY,
        #  BYHOUR, BYMINUTE, BYSECOND and BYSETPOS
        
        if @by['BYMONTH']
          bymon = @by['BYMONTH'].split(',')
          bymon = bymon.collect { |m| m.to_i }
  #        debug bymon

          # In yearly, at  this point, month will always be nil. At other
          # frequencies, it will not.
          days.intersect_bymon(bymon)

  #        debug days
        end

        # TODO - BYWEEKNO

        if @by['BYYEARDAY']
          byyday = @by['BYYEARDAY'].scan(/,?([+-]?[1-9]\d*)/)
  #        debug byyday
          dates = byyearday(t.year, byyday)
          days.intersect_dates(dates)
        end

        if @by['BYMONTHDAY']
          bymday = @by['BYMONTHDAY'].scan(/,?([+-]?[1-9]\d*)/)
  #        debug bymday
          # Generate all days matching this for all months. For yearly, this
          # is what we want, for anything of monthly or higher frequency, it
          # is too many days, but that's OK, since  the month will already
          # be specified and intersection will eliminate the out-of-range
          # dates.
          dates = bymonthday(t.year, bymday)
  #        debug dates
          days.intersect_dates(dates)
  #        debug days
        end

        if @by['BYDAY']
          byday = @by['BYDAY'].scan(/,?([+-]?[1-9]?\d*)?(SU|MO|TU|WE|TH|FR|SA)/i)
  #        debug byday

          # BYDAY means different things in different frequencies. The +n+
          # is only meaningful when freq is yearly or monthly.

          case @freq
            when 'YEARLY'
              dates = byday_in_yearly(t.year, byday)
            when 'MONTHLY'
              dates = byday_in_monthly(t.year, t.month, byday)
            when 'WEEKLY'
              # dates = byday_in_weekly(t.year, wkstart, t.month, t.day, byday)
            when 'DAILY', 'HOURLY', 'MINUTELY', 'SECONDLY'
              # Reuse the byday_in_monthly. Current day is already specified,
              # so this will just eliminate the current day if its not allowed
              # in BYDAY.
              dates = byday_in_monthly(t.year, t.month, byday)
          end

  #        debug dates
          days.intersect_dates(dates)
  #        debug days
        end

        # TODO - BYHOUR, BYMINUTE, BYSECOND
        
        # TODO - BYSETPOS

        # Yield the time, if we haven't gone over COUNT, or past UNTIL, or past
        # the end of representable time.

        hour   = [@dtstart.hour]   if !hour 
        min    = [@dtstart.min]    if !min  
        sec    = [@dtstart.sec]    if !sec 

  #      debug days

        days.each do |m,d|
            hour.each do |h|
              min.each do |n|
                sec.each do |s|
                  if(@count && (count > @count))
                    return self
                  end
                  y = Time.local(t.year, m, d, h, n, s, 0)

                  next if y.hour != h

                  # The generated set can sometimes generate results earlier
                  # than the DTSTART, skip them.
                  next if y < @dtstart

                  # We are done if current time is past @until.
                  if @until && (y > @until)
                    return self
                  end
                  # We are also done if current time is past the
                  # caller-requested until.
                  if dountil && (y >= dountil)
                    return self
                  end
                  yield y
                  count += 1
                end
              end
            end
        end


        # Add @interval to @freq component

        # Note - when we got past representable time, the error is:
        #   time out of range (ArgumentError)
        # Finish when we see this.
        begin
          case @freq
            when 'YEARLY' then
              t = t.plus_year(@interval)

            when 'MONTHLY' then
              t = t.plus_month(@interval)

            when 'WEEKLY' then
              t = t.plus_day(@interval * 7)

            when 'DAILY' then
              t = t.plus_day(@interval)

            when 'HOURLY' then
              t += @interval * 60 * 60

            when 'MINUTELY' then
              t += @interval * 60

            when 'SECONDLY' then
              t += @interval

            when nil
              return self
          end
        rescue ArgumentError
          return self if $!.message =~ /^time out of range$/

          raise ArgumentError, "#{$!.message} while adding interval to #{t.inspect}"
        end

        return self if dountil && (t > dountil)
      end
    end

    class DaySet #:nodoc:

      def initialize(ref)
        @ref = ref # Need to know because leap years have an extra day, and to get
                     # our defaults.
        @month = nil
        @week = nil
      end

      def month=(mon)
        @month = { mon => nil }
      end

      def week=(week)
        @week = week
      end

      def mday=(pair)
        @month = { pair[0] => [ pair[1] ] }
      end

      def intersect_bymon(bymon) #:nodoc:
        if !@month
          @month = {}
          bymon.each do |m|
            @month[m] = nil
          end
        else
          @month.delete_if { |m, days| ! bymon.include? m }
        end
      end

      def intersect_dates(dates) #:nodoc:
        if dates
          # If no months are in the dayset, add all the ones in dates
          if !@month
            @month = {}

            dates.each do |d|
              @month[d.mon] = nil
            end
          end

          # In each month,
          #   if there are days,
          #     eliminate those not in dates
          #   otherwise
          #     add all those in dates
          @month.each do |mon, days|
            days_in_mon = dates.find_all { |d| d.mon == mon }
            days_in_mon = days_in_mon.collect { |d| d.day }

            if days
              days_in_mon = days_in_mon & days
            end
            @month[mon] = days_in_mon
          end
        end
      end

      def each
        @month  = { @ref.month => [ @ref.mday ] } if !@month
        @month.each_key do |m|
          @month[m] = [@ref.day] if !@month[m]
          # FIXME - if @ref.day is 31, and the month doesn't have 32 days, we'll
          # generate invalid dates here, check for that, and eliminate them
        end

        @month.keys.sort.each do |m|
          @month[m].sort.each do |d|
            yield m, d
          end
        end
      end
    end

    def self.time_from_rfc2425(str) #:nodoc:
      # With ruby1.8 we can use DateTime to do this quick-n-easy:
      #  dt = DateTime.parse(str)
      #  Time.local(dt.year, dt.month, dt.day, dt.hour, dt.min, dt.sec, 0)

      # The time can be a DATE or a DATE-TIME, the latter always has a 'T' in it.

      if str =~ /T/
        d = Vpim.decode_date_time(str)
        # We get [ year, month, day, hour, min, sec, usec, tz ]
        if(d.pop == "Z")
          t = Time.gm(*d)
        else
          t = Time.local(*d)
        end
      else
        d = Vpim.decode_date(str)
        # We get [ year, month, day ]
        # FIXME - I have to choose gm or local, though neither makes much
        # sense. This is a bit of a hack - what we should really do is return
        # an instance of Date, and Time should allow itself to be compared to
        # Date... This hack will give odd results when comparing times, because
        # it will create a Time on the right date but whos time is 00:00:00.
        t = Time.local(*d)
      end
      if t.month != d[1] || t.day != d[2] || (d[3] && t.hour != d[3])
        raise Vpim::InvalidEncodingError, "Error - datetime does not exist"
      end
      t
    end

    def bymonthday(year, bymday) #:nodoc:
      dates = []

      bymday.each do |mday|
        dates |= DateGen.bymonthday(year, nil, mday[0].to_i)
      end
      dates.sort!
      dates
    end

    def byyearday(year, byyday) #:nodoc:
      dates = []

      byyday.each do |yday|
        dates << Date.new2(year, yday[0].to_i)
      end
      dates.sort!
      dates
    end

    def byday_in_yearly(year, byday) #:nodoc:
      byday_in_monthly(year, nil, byday)
    end

    def byday_in_monthly(year, mon, byday) #:nodoc:
      dates = []

      byday.each do |rule|
        if rule[0].empty?
          n = nil
        else
          n = rule[0].to_i
        end
        dates |= DateGen.bywday(year, mon, Date.str2wday(rule[1]), n)
      end
      dates.sort!
      dates
    end

  end

end

