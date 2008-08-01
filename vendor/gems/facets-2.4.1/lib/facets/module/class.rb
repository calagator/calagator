class Module

  # Alias for #===. This provides a verbal method
  # for inquery.
  #
  #   s = "HELLO"
  #   s.class? String   #=> true
  #
  #  CREDIT: Trans

  alias_method :class?, :===

end

