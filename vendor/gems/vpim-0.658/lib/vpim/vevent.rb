=begin
  Copyright (C) 2008 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

require 'vpim/dirinfo'
require 'vpim/field'
require 'vpim/rfc2425'
require 'vpim/rrule'
require 'vpim/vpim'
require 'vpim/property/base'
require 'vpim/property/common'
require 'vpim/property/priority'
require 'vpim/property/location'
require 'vpim/property/resources'
require 'vpim/property/recurrence'

module Vpim
  class Icalendar
    class Vevent

      include Vpim::Icalendar::Property::Base
      include Vpim::Icalendar::Property::Common
      include Vpim::Icalendar::Property::Priority
      include Vpim::Icalendar::Property::Location
      include Vpim::Icalendar::Property::Resources
      include Vpim::Icalendar::Property::Recurrence

      def initialize(fields) #:nodoc:
        outer, inner = Vpim.outer_inner(fields)

        @properties = Vpim::DirectoryInfo.create(outer)

        @elements = inner

        # See "TODO - fields" in dirinfo.rb
      end

      # TODO - derive everything from Icalendar::Component to get rid of this kind of stuff?
      def fields #:nodoc:
        f = @properties.to_a
        last = f.pop
        f.push @elements
        f.push last
      end

      def properties #:nodoc:
        @properties
      end

      # Create a new Vevent object. All events must have a DTSTART field,
      # specify it as either a Time or a Date in +start+, it defaults to "now"
      #
      # If specified, +fields+ must be either an array of Field objects to
      # add, or a Hash of String names to values that will be used to build
      # Field objects. The latter is a convenient short-cut allowing the Field
      # objects to be created for you when called like:
      #
      #   Vevent.create(Date.today, 'SUMMARY' => "today's event")
      #
      def Vevent.create(start = Time.now, fields=[])
        # TODO
        # - maybe events are usually created in a particular way? With a
        # start/duration or a start/end? Maybe I can make it easier. Ideally, I
        # would like to make it hard to encode an invalid Event.
        # - I don't think its useful to have a default dtstart for events
        # - also, I don't think dstart is mandatory
        dtstart = DirectoryInfo::Field.create('DTSTART', start)
        di = DirectoryInfo.create([ dtstart ], 'VEVENT')

        Vpim::DirectoryInfo::Field.create_array(fields).each { |f| di.push_unique f }

        new(di.to_a)
      end

      # Creates a yearly repeating event, such as for a birthday.
      def Vevent.create_yearly(date, summary)
        create(
          date,
          'SUMMARY' => summary.to_str,
          'RRULE' => 'FREQ=YEARLY'
          )
      end

      # Accept an event invitation. The +invitee+ is the Address that wishes
      # to accept the event invitation as confirmed.
      #
      # The event created is identical to this one, but
      # - without the attendees
      # - with the invitee added with a PARTSTAT of ACCEPTED
      def accept(invitee)
        # FIXME - move to Vpim::Itip.
        invitee = invitee.copy
        invitee.partstat = 'ACCEPTED'

        fields = []

        @properties.each_with_index do
          |f,i|

          # put invitee in as field[1]
          fields << invitee.encode('ATTENDEE') if i == 1
          
          fields << f unless f.name? 'ATTENDEE'
        end

        Vevent.new(fields)
      end

      # In iTIP, whether this event is OPAQUE or TRANSPARENT to scheduling. If
      # transparency is not explicitly set, it defaults to OPAQUE.
      def transparency
        proptoken 'TRANSP', ["OPAQUE", "TRANSPARENT"], "OPAQUE"
      end

      # The duration in seconds of an Event, or nil if unspecified. If the
      # DURATION field is not present, but the DTEND field is, the duration is
      # calculated from DTSTART and DTEND.  Durations of zero seconds are
      # possible.
      def duration
        propduration 'DTEND'
      end

      # The end time for this Event. If the DTEND field is not present, but the
      # DURATION field is, the end will be calculated from DTSTART and
      # DURATION.
      def dtend
        propend 'DTEND'
      end

      # Make a new Vevent, or make changes to an existing Vevent.
      class Maker
        include Vpim::Icalendar::Set::Util #:nodoc:
        include Vpim::Icalendar::Set::Common

        # The event that changes are being made to.
        attr_reader :event

        def initialize(event) #:nodoc:
          @event = event
          @comp = event
        end

        # Make changes to +event+. If +event+ is not specified, creates a new
        # event. Yields a Vevent::Maker, and returns +event+.
        def self.make(event = Vpim::Icalendar::Vevent.create) #:yield:maker
          m = self.new(event)
          yield m
          m.event
        end

        # Set transparency to "OPAQUE" or "TRANSPARENT", see Vpim::Vevent#transparency.
        def transparency(token)
          set_token 'TRANSP', ["OPAQUE", "TRANSPARENT"], "OPAQUE", token
        end

        # Set end for events with fixed durations. +end+ can be a Date or Time
        def dtend(dtend)
          set_date_or_datetime 'DTEND', 'DATE-TIME', dtend
        end

        # Add a RRULE to this event. The rule can be provided as a pre-build
        # RRULE value, or the RRULE maker can be used.
        def add_rrule(rule = nil, &block) #:yield: Rrule::Maker
          # TODO - should be in Property::Reccurrence::Set
          unless rule
            rule = Rrule::Maker.new(&block).encode
          end
          @comp.properties.push(Vpim::DirectoryInfo::Field.create("RRULE", rule))
          self
        end

        # Set the RRULE for this event. See #add_rrule
        def set_rrule(rule = nil, &block) #:yield: Rrule::Maker
          rm_all("RRULE")
          add_rrule(rule, &block)
        end

      end

    end
  end
end

