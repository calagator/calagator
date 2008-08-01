module Kernel

  # Easy access to an object's "special" class,
  # otherwise known as it's eigen or meta class.

  def singleton_class(&block)
    if block_given?
      (class << self; self; end).class_eval(&block)
    else
      (class << self; self; end)
    end
  end

end
