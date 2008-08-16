=begin
  Copyright (C) 2008 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

require "enumerator"

module Vpim
  class Icalendar
    module Property

      # Occurrences are calculated from DTSTART and RRULE. If there is no
      # RRULE, the component occurs only once, at the start time.
      #
      # Limitations:
      #
      # Only a single RRULE: is currently supported, this is the most common
      # case.
      module Recurrence
        def rrule #:nodoc:
          start = dtstart
          unless start
            raise ArgumentError, "Components without a DTSTART don't have occurrences!"
          end
          Vpim::Rrule.new(start, propvalue('RRULE'))
        end

        # The times this components occurs. If a block is not provided, returns
        # an enumerator.
        #
        # Occurrences may be infinite, +dountil+ can be provided to limit the
        # iterations, see Rrule#each.
        def occurrences(dountil = nil, &block) #:yield: occurrence time
          rr = rrule
          unless block_given?
            return Enumerable::Enumerator.new(self, :occurrences, dountil)
          end

          rr.each(dountil, &block)
        end

        alias occurences occurrences #:nodoc: backwards compatibility

        # True if this components occurs in a time period later than +t0+, but
        # earlier than +t1+.
        def occurs_in?(t0, t1)
          # TODO - deprecate this, its a hack
          occurrences(t1).detect do |tend|
            if respond_to? :duration
              tend += duration || 0
            end
            tend >= t0
          end
        end

        def rdates #:nodoc:
          # TODO - this is a hack, remove it
          Vpim.decode_date_time_list(propvalue('RDATE'))
        end

      end
    end
  end
end


