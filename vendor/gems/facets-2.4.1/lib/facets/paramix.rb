# TITLE:
#
#   Parametric Mixins
#
# SUMMARY:
#
#   Parametric Mixins provides parameters for mixin modules.
#
# COPYRIGHT:
#
#   Copyright (c) 2008 T. Sawyer
#
# LICENSE:
#
#   Ruby License
#
#   This module is free software. You may use, modify, and/or redistribute this
#   software under the same terms as Ruby.
#
#   This program is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
#   FOR A PARTICULAR PURPOSE.
#
# AUTHORS:
#
#   - Thomas Sawyer

require 'facets/module/basename'
require 'facets/module/modspace'

# = Parametric Mixin
#
# Parametric Mixins provides parameters for mixin modules.
# Module parameters can be set at the time of inclusion or extension,
# then accessed via an instance method per mixin.
#
#   module Mixin
#     def hello
#       puts "Hello from #{mixin_parameters[Mixin][:name]}"
#     end
#   end
#
#   class MyClass
#     include Mixin(:name => 'Ruby')
#   end
#
#   m = MyClass.new
#   m.hello -> 'Hello from Ruby'
#
# You can view the full set of parameters via the #mixin_parameters
# class method, which returns a hash keyed on the included modules.
#
#   MyClass.mixin_parameters         #=> {Mixin=>{:name=>'Ruby'}}
#   MyClass.mixin_parameters[Mixin]  #=> {:name=>'Ruby'}
#
# To create _dynamic mixins_ you can use the #included callback
# method along with mixin_parameters method like so:
#
#   module Mixin
#     def self.included( base )
#       parms = base.mixin_parameters[self]
#       base.class_eval {
#         def hello
#           puts "Hello from #{parms(:name)}"
#         end
#       }
#     end
#   end
#
#--
# More conveniently a new callback has been added, #included_with_parameters,
# which passes in the parameters in addition to the base class/module.
#
#   module Mixin
#     def self.included_with_parameters( base, parms )
#       base.class_eval {
#         def hello
#           puts "Hello from #{parms(:name)}"
#         end
#       }
#     end
#   end
#
# We would prefer to have passed the parameters through the #included callback
# method itself, but implementation of such a feature is much more complicated.
# If a reasonable solution presents itself in the future however, we will fix.
#++

module Paramix  # or PatrametricMixin ?

  def self.append_features(base)
    base.modspace.module_eval %{
      def #{base.basename.to_s}(parameters, &block)
        Delegator.new(#{base}, parameters, &block)
      end
    }
  end

  # It you want to define the module method by hand. You
  # can use Parmix.new instead of Parmix::Delegator.new.

  def self.new(delegate_module, parameters={}, &base_block)
    Delegator.new(delegate_module, parameters, &base_block)
  end

  #

  class Delegator < Module

    attr :delegate_module
    attr :parameters
    attr :base_block

    def initialize(delegate_module, parameters={}, &base_block)
      @delegate_module = delegate_module
      @parameters      = parameters
      @base_block      = base_block
    end

    def append_features(base)
      base.__send__(:include, delegate_module)

      base.mixin_parameters[delegate_module] = parameters

      base.module_eval do 
        define_method(:mixin_parameters) do
          base.mixin_parameters
        end
      end

      base.module_eval(&@base_block) if base_block
    end

    def [](name)
      @parameters[name]
    end

  end

end


class Module

  # Store for parametric mixin parameters.
  #
  # Returns a hash, the keys of which are the parametric mixin module
  # and the values are the parameters associacted with this module/class.
  #
  #   class C
  #     include P(:x=>1)
  #   end
  #
  #   C.mixin_parameters[P]   #=> {:x=>1}
  #
  def mixin_parameters
    @mixin_parameters ||= {}
  end

end


if __FILE__ == $0

  module O
    include Paramix

    def x
      mixin_parameters[O][:x]
    end
  end

  #def O(options)
  #  Paramix.new(O, options)
  #end

  class X
    include O(:x=>1)
  end

  x = X.new
  p x.x

  p X.ancestors

end

