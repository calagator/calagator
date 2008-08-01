module Enumerable

  # Split on matching pattern. Unlike #divide this does not include matching elements.
  #
  #   ['a1','a2','b1','a3','b2','a4'].split(/^b/)
  #   => [['a1','a2'],['a3'],['a4']]
  #
  # CREDIT: Trans

  def split(pattern)
    memo = []
    each do |obj|
      if pattern === obj
        memo.push []
      else
        memo.last << obj
      end
    end
    memo
  end

end

