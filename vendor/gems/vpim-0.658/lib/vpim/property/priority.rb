=begin
  Copyright (C) 2008 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

module Vpim
  class Icalendar
    module Property
      module Priority

        # +priority+ is a number from 1 to 9, with 1 being the highest
        # priority, 9 being the lowest. 0 means "no priority", equivalent to
        # not specifying the PRIORITY field.
        #
        # The other integer values are reserved by RFC2445.
        #
        # TODO
        # - methods to compare priorities?
        # - return as class Priority, with #to_i, and #to_s, and appropriate
        #   comparison operators?
        def priority
          p = @properties.detect { |f| f.name? 'PRIORITY' }
          
          if !p
            p = 0
          else
            p = p.value.to_i

            if( p < 0 || p > 9 )
              raise Vpim::InvalidEncodingError, 'Invalid priority #{@priority} - it must be 0-9!'
            end
          end
          p
        end
      end
    end
  end
end


