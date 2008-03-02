=begin
  Copyright (C) 2006 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

require 'date'

# Extensions to the standard library Date.
class Date

  TIME_START = Date.new(1970, 1, 1)
  SECS_PER_DAY = 24 * 60 * 60

  # Converts this object to a Time object, or throws an ArgumentError if
  # conversion is not possible because it is before the start of epoch.
  def to_time
    raise ArgumentError, 'date is before the start of system time' if self < TIME_START
    days = self - TIME_START

    Time.at((days * SECS_PER_DAY).to_i)
  end

  # If wday responds to to_str, convert it to the wday number by searching for
  # a wday that matches, using as many characters as are in wday to do the
  # comparison. wday must be 2 or more characters long in order to be a unique
  # match, other than that, "mo", "Mon", and "MonDay" are all valid strings
  # for wday 1.
  #
  # This method can be called on a valid wday, and it will return it. Perhaps
  # it should be called by default inside the Date#new*() methods so that
  # non-integer wday arguments can be used? Perhaps a similar method should
  # exist for months? But with months, we all know January is 1, who can
  # remember where Date chooses to start its wday count!
  #
  # Examples:
  #  Date.bywday(2004, 2, Date.str2wday('TU')) => the first Tuesday in
  #    February
  #  Date.bywday(2004, 2, Date.str2wday(2)) => the same day, but notice
  #    that a valid wday integer can be passed right through.
  #   
  def Date.str2wday(wdaystr)
    return wdaystr unless wdaystr.respond_to? :to_str

    str = wdaystr.to_str.upcase
    if str.length < 2
      raise ArgumentError, 'wday #{wday} is not long enough to be a unique weekday name'
    end

    wday = Date::DAYNAMES.map { |n| n.slice(0, str.length).upcase }.index(str)

    return wday if wday

    raise ArgumentError, 'wday #{wdaystr} was not a recognizable weekday name'
  end

  
  # Create a new Date object for the date specified by year +year+, month
  # +mon+, and day-of-the-week +wday+.
  #
  # The nth, +n+, occurrence of +wday+ within the period will be generated
  # (+n+ defaults to 1).  If +n+ is positive, the nth occurence from the
  # beginning of the period will be returned, if negative, the nth occurrence
  # from the end of the period will be returned.
  #
  # The period is a year, unless +month+ is non-nil, in which case it is just
  # that month.
  #
  # Examples:
  # - Date.bywday(2004, nil, 1, 9) => the ninth Sunday of 2004
  # - Date.bywday(2004, nil, 1) => the first Sunday of 2004
  # - Date.bywday(2004, nil, 1, -2) => the second last Sunday of 2004
  # - Date.bywday(2004, 12, 1) => the first sunday in the 12th month of 2004
  # - Date.bywday(2004, 2, 2, -1) => last Tuesday in the 2nd month in 2004
  # - Date.bywday(2004, -2, 3, -2) => second last Wednesday in the second last month of 2004
  #
  # Compare this to Date.new, which allows a Date to be created by
  # day-of-the-month, mday, to Date.new2, which allows a Date to be created by
  # day-of-the-year, yday, and to Date.neww, which allows a Date to be created
  # by day-of-the-week, but within a specific week.
  def Date.bywday(year, mon, wday, n = 1, sg=Date::ITALY)
    # Normalize mon to 1-12.
    if mon
      if mon > 12 ||  mon == 0 || mon < -12
         raise ArgumentError, "mon #{mon} must be 1-12 or negative 1-12"
      end
      if mon < 0
        mon = 13 + mon
      end
    end
    if wday < 0 || wday > 6
      raise ArgumentError, 'wday must be in range 0-6, or a weekday name'
    end

    # Determine direction of indexing.
    inc = n <=> 0
    if inc == 0
      raise ArgumentError, 'n must be greater or less than zero'
    end

    # if !mon, n is index into year, but direction of search is determined by
    # sign of n
    d = Date.new(year, mon ? mon : inc, inc, sg)

    while d.wday != wday
      d += inc
    end

    # Now we have found the first/last day with the correct wday, search
    # for nth occurrence, by jumping by n.abs-1 weeks forward or backward.
    d += 7 * (n.abs - 1) * inc

    if d.year != year
      raise ArgumentError, 'n is out of bounds of year'
    end
    if mon && d.mon != mon
      raise ArgumentError, 'n is out of bounds of month'
    end
    d
  end
end

# DateGen generates arrays of dates matching simple criteria.
class DateGen
  # Generate an array of dates on +wday+ (the day-of-week,
  # 0-6, where 0 is Sunday).
  #
  # If +n+ is specified, only the nth occurrence of +wday+ within the period
  # will be generated.  If +n+ is positive, the nth occurence from the
  # beginning of the period will be returned, if negative, the nth occurrence
  # from the end of the period will be returned.
  #
  # The period is a year, unless +month+ is non-nil, in which case it is just
  # that month.
  #
  # Examples:
  # - DateGen.bywday(2004, nil, 1, 9) => the ninth Sunday in 2004
  # - DateGen.bywday(2004, nil, 1) => all Sundays in 2004
  # - DateGen.bywday(2004, nil, 1, -2) => second last Sunday in 2004
  # - DateGen.bywday(2004, 12, 1) => all sundays in December 2004
  # - DateGen.bywday(2004, 2, 2, -1) => last Tuesday in February in 2004
  # - DateGen.bywday(2004, -2, 3, -2) => second last Wednesday in November of 2004
  #
  # Compare to Date.bywday(), which allows a single Date to be created with
  # similar criteria.
  def DateGen.bywday(year, month, wday, n = nil)
    seed = Date.bywday(year, month, wday, n ? n : 1)

    dates = [ seed ]

    return dates if n

    succ = seed.clone

    # Collect all matches until we're out of the year (or month, if specified)
    loop do
      succ += 7

      break if succ.year != year
      break if month && succ.month != seed.month

      dates.push succ
    end
    dates.sort!
    dates
  end

  # Generate an array of dates on +mday+ (the day-of-month, 1-31). For months
  # in which the +mday+ is not present, no date will be generated.
  #
  # The period is a year, unless +month+ is non-nil, in which case it is just
  # that month.
  #
  # Compare to Date.new(), which allows a single Date to be created with
  # similar criteria.
  def DateGen.bymonthday(year, month, mday)
    months = month ? [ month ] : 1..12
    dates = [ ]

    months.each do |m|
      begin
        dates << Date.new(year, m, mday)
      rescue ArgumentError
        # Don't generate dates for invalid combinations (Feb 29, when it's not
        # a leap year, for example).
        #
        # TODO - should we raise when month is out of range, or mday can never
        # be in range (32)?
      end
    end
    dates
  end
end

