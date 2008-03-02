=begin
  Copyright (C) 2006 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

module Vpim
  # This is a way for an object to have multiple ways of being enumerated via
  # argument to it's #each() method. An Enumerator mixes in Enumerable, so the
  # standard APIS such as Enumerable#map(), Enumerable#to_a(), and
  # Enumerable#find_all() can be used on it.
  class Enumerator
    include Enumerable

    def initialize(obj, *args)
      @obj = obj
      @args = args
    end

    def each(&block)
      @obj.each(*@args, &block)
    end
  end
end

