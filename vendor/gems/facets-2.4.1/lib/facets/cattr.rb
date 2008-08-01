# = CAttr
#
# Class/Instance attributes.
#
# == Notes
#
# * This was suggested by Ara T. Howard
#
# == Authors
#
# * Thomas Sawyer
#
# == Copying
#
# Copyright (c) 2006 Thomas Sawyer
#
# Ruby License
#
# This module is free software. You may use, modify, and/or redistribute this
# software under the same terms as Ruby.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.

class Class

  # Creates a class-variable attribute that can
  # be accessed both on an instance and class level.
  #
  # NOTE This used to be a Module method. But turns out
  # it does not work as expected when included. The class-level
  # method is not carried along. So it is now just class
  # method. Accordingly, #mattr will eventually be deprecated,
  # so use #cattr instead.
  #
  #  CREDIT: David Heinemeier Hansson

  def cattr( *syms )
    accessors, readers = syms.flatten.partition { |a| a.to_s =~ /=$/ }
    writers = accessors.collect{ |e| e.to_s.chomp('=').to_sym }
    readers.concat( writers )
    cattr_writer( *writers )
    cattr_reader( *readers )
    return readers + accessors
  end

  # Creates a class-variable attr_reader that can
  # be accessed both on an instance and class level.
  #
  #   class MyClass
  #     @@a = 10
  #     cattr_reader :a
  #   end
  #
  #   MyClass.a           #=> 10
  #   MyClass.new.a       #=> 10
  #
  #  CREDIT: David Heinemeier Hansson

  def cattr_reader( *syms )
    syms.flatten.each do |sym|
      class_eval(<<-EOS, __FILE__, __LINE__)
        def self.#{sym}
          @@#{sym}
        end
        def #{sym}
          @@#{sym}
        end
      EOS
    end
    return syms
  end

  # Creates a class-variable attr_writer that can
  # be accessed both on an instance and class level.
  #
  #   class MyClass
  #     cattr_writer :a
  #     def a
  #       @@a
  #     end
  #   end
  #
  #   MyClass.a = 10
  #   MyClass.a            #=> 10
  #   MyClass.new.a = 29
  #   MyClass.a            #=> 29
  #
  #  CREDIT: David Heinemeier Hansson

  def cattr_writer(*syms)
    syms.flatten.each do |sym|
      class_eval(<<-EOS, __FILE__, __LINE__)
        def self.#{sym}=(obj)
          @@#{sym} = obj
        end
        def #{sym}=(obj)
          @@#{sym}=(obj)
        end
      EOS
    end
    return syms
  end

  # Creates a class-variable attr_accessor that can
  # be accessed both on an instance and class level.
  #
  #   class MyClass
  #     cattr_accessor :a
  #   end
  #
  #   MyClass.a = 10
  #   MyClass.a           #=> 10
  #   mc = MyClass.new
  #   mc.a                #=> 10
  #
  #  CREDIT: David Heinemeier Hansson

  def cattr_accessor(*syms)
    m = []
    m.concat( cattr_reader(*syms) )
    m.concat( cattr_writer(*syms) )
    m
  end

end


#class Module
  # NOTE: Module variations turn out not to work, because
  # the class-level method created is not inherited when the
  # module is included. Accordingly, #mattr and friends
  # will be deprecated, so use #cattr instead.

  #alias_method :mattr,          :cattr            # deprecate
  #alias_method :mattr_reader,   :cattr_reader     # deprecate
  #alias_method :mattr_writer,   :cattr_writer     # deprecate
  #alias_method :mattr_accessor, :cattr_accessor   # deprecate
#end

