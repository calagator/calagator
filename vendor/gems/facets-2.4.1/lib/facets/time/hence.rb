class Time

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

