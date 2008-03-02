=begin
  Copyright (C) 2006 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

require 'vpim/dirinfo'
require 'vpim/field'
require 'vpim/rfc2425'
require 'vpim/vpim'
require 'vpim/property/base'
require 'vpim/property/common'
require 'vpim/property/recurrence'

module Vpim
  class Icalendar

    class Vjournal
      include Vpim::Icalendar::Property::Base
      include Vpim::Icalendar::Property::Common
      include Vpim::Icalendar::Property::Recurrence

      def initialize(fields) #:nodoc:
        outer, inner = Vpim.outer_inner(fields)

        @properties = Vpim::DirectoryInfo.create(outer)

        @elements = inner
      end

      # Create a Vjournal component.
      def self.create(fields=[])
        di = DirectoryInfo.create([], 'VJOURNAL')

        Vpim::DirectoryInfo::Field.create_array(fields).each { |f| di.push_unique f }

        new(di.to_a)
      end

    end

  end
end

