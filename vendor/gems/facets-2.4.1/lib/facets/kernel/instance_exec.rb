require 'facets/proc/bind'

unless (RUBY_VERSION[0,3] == '1.9')

  module Kernel

    # Like instance_eval but allows parameters to be passed.
    #
    # NOTE: This is deprecated b/c implementation is fragile.
    # Use Ruby 1.9 instead.

    def instance_exec(*arguments, &block)
      block.bind(self)[*arguments]
    end

  end

end

