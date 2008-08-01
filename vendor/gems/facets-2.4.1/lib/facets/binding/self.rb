require 'facets/ruby' #for Binding#eval

class Binding

  # Returns self of the binding context.

  def self()
    @_self ||= eval("self")
  end

end

