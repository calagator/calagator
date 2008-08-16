=begin
  Copyright (C) 2008 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

module Vpim
  class Icalendar
    module Property

      module Resources

        def resources
          proptextlistarray 'RESOURCES'
        end

      end
    end
  end
end


