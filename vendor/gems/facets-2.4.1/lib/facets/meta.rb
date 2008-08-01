require 'facets/functor'

module Kernel

  # Provides access to an object's metaclass (ie. singleton)
  # by-passsing access provisions. So for example:
  #
  #   class X
  #     meta.attr_accesser :a
  #   end
  #
  #   X.a = 1
  #   X.a #=> 1
  #
  #  CREDIT: Trans

  def meta
    @_meta_functor ||= Functor.new do |op,*args|
      (class << self; self; end).send(op,*args)
    end
  end

end
