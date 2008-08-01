require 'facets/ruby'

class Array

  # Operator alias for cross-product.
  #
  #   a = [1,2] ** [4,5]
  #   a  #=> [[1, 4],[1, 5],[2, 4],[2, 5]]
  #
  #  CREDIT: Trans

  alias_method :**, :product

end

