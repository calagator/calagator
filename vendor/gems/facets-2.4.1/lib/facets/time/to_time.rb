require 'time'

class String

  # Parse string to time.
  #
  #  CREDIT: Trans

  def to_time
    Time.parse(self)
  end

end

