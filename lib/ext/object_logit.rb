# = Object#logit
#
# Provides easy-to-access Rails logging
#
# == Example
#
# The following creates a new Foo class with some methods that call
# logit:
#
#   class Foo
#     def bar
#       logit "meh"
#     end
#
#     def self.baz
#       logit "meh"
#     end
#   end
#
# Now lets call those methods and you'll see messages recorded in the
# Rails logs:
#   Foo.new.bar # => "Foo#bar: meh"
#   Foo.baz     # => "Foo::baz: meh"
class Object
  # Return string with a log message which includes the class, method and
  # a user-specified +message+.
  #
  # For example, if you have an instance of MyClass and are using the
  # #my_instance_method method with the "my message" logit message,
  # you'll get output like this:
  #
  #   MyClass#my_instance_method: my message
  def logmsg(message="Hello world", depth=1)
    from = caller(depth).first
    return "#{self.kind_of?(Class) ? self.to_s+'::' : self.class.to_s+'#'}#{from[/in `([^']+)'/, 1]}: #{message}"
  end

  # Log a +message+ using Rails. Optional +level+ (e.g. "info"). See
  # #logmsg for details on log format.
  def logit(message="Hello world", level=:info, depth=2)
    output = self.logmsg(message, depth)
    RAILS_DEFAULT_LOGGER.send(level, output)
    return output
  end
end
