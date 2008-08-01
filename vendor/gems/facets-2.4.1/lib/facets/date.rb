# = Date Extended
#
# Ruby's standard Date class with a few extensions.
#
# == Authors
#
# * Thomas Sawyer
#
# == Copying
#
#   Copyright (c) 2004 Thomas Sawyer
#
#   Ruby License
#
#   This module is free software. You may use, modify, and/or redistribute this
#   software under the same terms as Ruby.
#
#   This program is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
#   FOR A PARTICULAR PURPOSE.

require 'date'
require 'parsedate' # needed for String#to_date

class Date

  # To be able to keep Dates and Times
  # interchangeable on conversions.
  def to_date
    self
  end

  # Convert Date to Time.
  #
  def to_time(form = :local)
    ::Time.send(form, year, month, day)
  end

  # An enhanched #to_s method that cane take an optional
  # format flag of :short or :long.
  def stamp(format = nil)
    case format
    when :short
      strftime("%e %b").strip
    when :long
      strftime("%B %e, %Y").strip
    else
      strftime("%Y-%m-%d")  # standard to_s
    end
  end

  # Enhance #to_s by aliasing to #stamp.
  alias_method( :to_s, :stamp )

  # Returns the number of days in the date's month.
  #
  #   Date.new(2004,2).days_in_month #=> 28
  #
  #  CREDIT: Ken Kunz.

  def days_in_month
     Date.civil(year, month, -1).day
  end

  def days_of_month
    (1..days_in_month).to_a
  end

  # Get the month name for this date object
  #
  #  CREDIT Benjamin Oakes

  def month_name
    MONTHNAMES[self.month]
  end

end

class String

  # Parse data from string.
  #
  #  CREDIT: Trans

  def to_date
    ::Date::civil(*ParseDate.parsedate(self)[0..2])
  end

end

