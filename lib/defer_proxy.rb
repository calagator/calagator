# = DeferProxy
#
# Create a proxy for lazy-loading objects.
#
# == Example for Ruby
#
# In the example below, we create an @array variable that behaves just like an
# Array instance, but is actually a proxy that will return array content. The
# proxy materialies this content the first time that an instance method is
# called on it:
#
#   # Create a proxy using either the DeferProxy class or Defer method:
#   @array = DeferProxy.new { p "zzz"; sleep 1; p "yawn"; [1,2,3] }
#   @array = Defer { p "zzz"; sleep 1; p "yawn"; [1,2,3] }
#
#   # Access proxy to materialize results, it will execute slowly:
#   @array.size
#   # "zzz"
#   # "yawn"
#   # => 3
#
#   # Access proxy again, it will return materialized results immediately:
#   @array.size
#   # => 3
#
# == Example for Rails
#
# Deferred-instantiation proxies are useful in Rails applications because they
# help avoid slow operations while preserving MVC encapsulation.
#
# In the example below, the +Record+ class has a ::slow_operation method that
# we wish to avoid calling if possible. We create a proxy called @records in
# the #index controller action to describe how to fetch data. The view then
# uses the @records object within a #cache block that captures HTML emitted
# within that scope. If the view finds the fragment cache for this block, then
# the @records proxy object will never be used and the ::slow_operation never
# called, thus making the action much faster.
#
#   # Model
#   class Record < ActiveRecord::Base
#     def self.slow_operation
#       puts "Performing slow operation...."
#       sleep 3
#       puts "Completed slow operation!"
#       return [1,2,3]
#     end
#   end
#
#   # Action
#   def index
#     @records = Defer { Record.slow_operation }
#   end
#
#   # View
#   <% cache "record_index" do %>
#     <%= @records.size %>
#   <% end %>
class DeferProxy
  attr_accessor :__called
  attr_accessor :__callback
  attr_accessor :__value

  def initialize(&block)
    self.__callback = block
  end

  def __materialize(method=nil, *args, &block)
    unless self.__called
      Rails.logger.debug("DeferProxy materialized by: #{self.__value.class.name}##{method}") if defined?(Rails)

      # TODO Find a less horrible way than this "retry" mechanism for coping with Rails development mode reloads that periodically throw NoMethodError and pretend that there's a nil in the callback.
      tried = false
      begin
        self.__value = self.__callback.call
      rescue NoMethodError => e
        unless tried
          Rails.logger.debug("DeferProxy retrying: #{self.__value.class.name}##{method}")
          tried = true
          retry
        end
      end

      self.__called = true
    end
    return self.__value
  end

  def method_missing(method, *args, &block)
    self.__materialize(method)
    return self.__value.send(method, *args, &block)
  end

  alias_method :kind_of_old?, :kind_of?
  def kind_of_with_trickery?(klass)
    self.__materialize('kind_of?')
    # FIXME how to handle #to_a calls?
    # TODO Figure out why this causes a endless loop: self.kind_of_without_trickery?(DeferProxy)
    #return self.__value.kind_of?(klass) || self.kind_of_without_trickery?(klass)
    #return self.class == klass || self.kind_of_without_trickery?(klass) || self.__value.kind_of?(klass)
    return self.class == klass || self.__value.kind_of?(klass)
  end
  alias_method_chain :kind_of?, :trickery
end

# Return a DeferProxy instance for the given +block+.
def Defer(&block)
  return DeferProxy.new(&block)
end

# Return the content of a value, be it a Defer or not.
def Undefer(value)
  # TODO Surely there's a less hideous way!?
  return value.respond_to?(:kind_of_with_trickery?) ? value.__materialize : value
end

__END__

# Test
load 'lib/defer_proxy.rb'
x = Defer { [1,2,3] }
x.each{|v| p v}
x.kind_of? Array
x.kind_of? DeferProxy
