module Enumerable

  # In Statistics mode is the value that occurs most
  # frequently in a given set of data.
  #
  #  CREDIT: Trans

  def mode
    count = Hash.new(0)
    each {|x| count[x] += 1 }
    count.sort_by{|k,v| v}.last[0]
  end

end

