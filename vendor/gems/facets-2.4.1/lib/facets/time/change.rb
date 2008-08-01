class Time

  # Returns a new Time where one or more of the elements
  # have been changed according to the +options+ parameter.
  # The time options (hour, minute, sec, usec) reset
  # cascadingly, so if only the hour is passed, then
  # minute, sec, and usec is set to 0. If the hour and
  # minute is passed, then sec and usec is set to 0.
  #
  #  t = Time.now            #=> Sat Dec 01 14:10:15 -0500 2007
  #  t.change(:hour => 11)   #=> Sat Dec 01 11:00:00 -0500 2007
  #
  #  CREDIT: David Hansson (?)

  def change(options)
    opts={}; options.each_pair{ |k,v| opts[k] = v.to_i }
    self.class.send( self.utc? ? :utc : :local,
      opts[:year]  || self.year,
      opts[:month] || self.month,
      opts[:day]   || self.day,
      opts[:hour]  || self.hour,
      opts[:min]   || (opts[:hour] ? 0 : self.min),
      opts[:sec]   || ((opts[:hour] || opts[:min]) ? 0 : self.sec),
      opts[:usec]  || ((opts[:hour] || opts[:min] || opts[:usec]) ? 0 : self.usec)
    )
  end

  # Like change but does not reset earlier times.
  #
  # NOTE: It would be better, probably if this were called "change".
  #       and that #change were called "reset".

  def set(options)
    opts={}; options.each_pair{ |k,v| opts[k] = v.to_i }
    self.class.send( self.utc? ? :utc : :local,
      opts[:year]  || self.year,
      opts[:month] || self.month,
      opts[:day]   || self.day,
      opts[:hour]  || self.hour,
      opts[:min]   || self.min,
      opts[:sec]   || self.sec,
      opts[:usec]  || self.usec
    )
  end

  # Returns a new Time representing the time
  # a number of time-units ago.

  def ago(number, units=:seconds)
    case units.to_s.downcase.to_sym
    when :years
      set(:year=>(year - number))
    when :months
      years = (month - number / 12).to_i
      set(:year=>(year - years), :month=>(month - number) % 12)
    when :weeks
      self - (number * 604800)
    when :days
      self - (number * 86400)
    when :hours
      self - (number * 3600)
    when :minutes
      self - (number * 60)
    when :seconds, nil
      self - number
    else
      raise ArgumentError, "unrecognized time units -- #{units}"
    end
  end

  # Returns a new Time representing the time
  # a number of time-units hence.

  def hence(number, units=:seconds)
    case units.to_s.downcase.to_sym
    when :years
      set(:year=>(year + number))
    when :months
      years = (month + number / 12).to_i
      set(:year=>(year + years), :month=>(month + number) % 12)
    when :weeks
      self + (number * 604800)
    when :days
      self + (number * 86400)
    when :hours
      self + (number * 3600)
    when :minutes
      self + (number * 60)
    when :seconds
      self + number
    else
      raise ArgumentError, "unrecognized time units -- #{units}"
    end
  end

  alias_method :in, :hence

end

