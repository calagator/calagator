class Class

  # List all descedents of this class.
  #
  #   class X ; end
  #   class A < X; end
  #   class B < X; end
  #   X.descendents  #=> [A,B]
  #
  # NOTE: This is a intesive operation. Do not
  # expect it to be super fast.

  def descendents
    subclass = []
    ObjectSpace.each_object( Class ) do |c|
      if c.ancestors.include?( self ) and self != c
        subclass << c
      end
    end
    return subclass
  end

  # Obvious alias for descendents.

  alias_method :subclasses, :descendents

end

