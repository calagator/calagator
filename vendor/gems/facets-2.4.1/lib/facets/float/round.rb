#require 'facets/numeric/round'

class Float

  # Float#round_off is simply an alias for Float#round.
  #alias_method :round_off, :round

  # Rounds to the given decimal position.
  #
  #   4.555.round_at(0)  #=> 5.0
  #   4.555.round_at(1)  #=> 4.6
  #   4.555.round_at(2)  #=> 4.56
  #   4.555.round_at(3)  #=> 4.555
  #
  #   CREDIT: Trans

  def round_at( d ) #d=0
    (self * (10.0 ** d)).round.to_f / (10.0 ** d)
  end

  # Rounds to the nearest _n_th degree.
  #
  #   4.555.round_to(1)     #=> 5.0
  #   4.555.round_to(0.1)   #=> 4.6
  #   4.555.round_to(0.01)  #=> 4.56
  #   4.555.round_to(0)     #=> 4.555
  #
  #   CREDIT: Trans

  def round_to( n ) #n=1
    return self if n == 0
    (self * (1.0 / n)).round.to_f / (1.0 / n)
  end

end

