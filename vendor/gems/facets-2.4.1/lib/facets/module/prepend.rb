class Module

  # Prepend an +aspect+ module to a module.
  #
  #   module X
  #     def x; "x"; end
  #   end
  #
  #   module U
  #     def x; '{' + super + '}'; end
  #   end
  #
  #   X.prepend U
  #
  #   X.x  # => "{x}"
  #
  #  CREDIT Trans

  def prepend(aspect)
    aspect.__send__(:include, self)
    extend aspect
  end

end

