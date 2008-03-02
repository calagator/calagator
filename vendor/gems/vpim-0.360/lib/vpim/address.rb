=begin
  Copyright (C) 2006 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

=begin

Notes on a CAL-ADDRESS

When used with ATTENDEE, the parameters are:
  CN
  CUTYPE
  DELEGATED-FROM
  DELEGATED-TO
  DIR
  LANGUAGE
  MEMBER
  PARTSTAT
  ROLE
  RSVP
  SENT-BY

When used with ORGANIZER, the parameters are:
  CN
  DIR
  LANGUAGE
  SENT-BY


What I've seen in Notes invitations, and iCal responses:
  ROLE
  PARTSTAT
  RSVP
  CN

Support these last 4, for now.

=end

module Vpim
  class Icalendar
    # Used to represent calendar fields containing CAL-ADDRESS values.
    # The organizer or the attendees of a calendar event are examples of such
    # a field.
    #
    # Example:
    #
    #   ORGANIZER;CN="A. Person":mailto:a_person@example.com
    #
    #   ATTENDEE;ROLE=REQ-PARTICIPANT;PARTSTAT=NEEDS-ACTION
    #    ;CN="Sam Roberts";RSVP=TRUE:mailto:SRoberts@example.com
    #
    class Address

      # Create a copy of Address. If the original Address was frozen, this one
      # won't be.
      def copy
        #Marshal.load(Marshal.dump(self))
        self.dup.dirty
      end

      def dirty #:nodoc:
        @field = nil
        self
      end

      # Addresses in a CAL-ADDRESS are represented as a URI, usually a mailto URI.
      attr_accessor :uri
      # The common or displayable name associated with the calendar address, or
      # nil if there is none.
      attr_accessor :cn
      # The participation role for the calendar user specified by the address.
      #
      # The standard roles are:
      # - CHAIR Indicates chair of the calendar entity
      # - REQ-PARTICIPANT Indicates a participant whose participation is required
      # - OPT-PARTICIPANT Indicates a participant whose participation is optional
      # - NON-PARTICIPANT Indicates a participant who is copied for information purposes only
      #
      # The default role is REQ-PARTICIPANT, returned if no ROLE parameter was
      # specified.
      attr_accessor :role
      # The participation status for the calendar user specified by the
      # property PARTSTAT, a String.
      #
      # These are the participation statuses for an Event:
      # - NEEDS-ACTION Event needs action
      # - ACCEPTED Event accepted
      # - DECLINED Event declined
      # - TENTATIVE Event tentatively accepted
      # - DELEGATED Event delegated
      #
      # Default is NEEDS-ACTION.
      #
      # FIXME - make the default depend on the component type.
      attr_accessor :partstat
      # The value of the RSVP field, either +true+ or +false+. It is used to
      # specify whether there is an expectation of a reply from the calendar
      # user specified by the property value.
      attr_accessor :rsvp

      def initialize(field=nil) #:nodoc:
        @field = field
        @uri = ''
        @cn = ''
        @role = "REQ-PARTICIPANT"
        @partstat = "NEEDS-ACTION"
        @rsvp = false
      end

      # Create a new Address. It will encode as a +name+ property.
      def self.create(uri='')
        adr = new
        adr.uri = uri.to_str
        adr
      end

      def self.decode(field)
        adr = new(field)
        adr.uri = field.value

        cn = field.param('CN')

        if cn
          adr.cn = cn.first
        end

        role = field.param('ROLE')

        if role
          adr.role = role.first.strip.upcase
        end

        partstat = field.param('PARTSTAT')

        if partstat
          adr.partstat = partstat.first.strip.upcase
        end
        
        rsvp = field.param('RSVP')

        if rsvp
          adr.rsvp = case rsvp.first
                     when /TRUE/i then true
                     when /FALSE/i then false
                     else raise InvalidEncodingError, "RSVP param value not TRUE/FALSE: #{rsvp}"
                     end
        end

        adr.freeze
      end

      # Return a representation of this Address as a DirectoryInfo::Field.
      def encode(name) #:nodoc:
        if @field
          # FIXME - set the field name, it could be different from cached
          return @field
        end

        value = uri.to_str.strip

        if value.empty?
          raise Uencodeable, "Address#uri is zero-length"
        end

        params = {}

        if cn.length > 0
          params['CN'] = Vpim::encode_paramvalue(cn)
        end

        # FIXME - default value is different for non-vEvent
        if role.length > 0 && role != 'REQ-PARTICIPANT'
          params['ROLE'] = Vpim::encode_paramtext(role)
        end

        # FIXME - default value is different for non-vEvent
        if partstat.length > 0 && partstat != 'NEEDS-ACTION'
          params['PARTSTAT'] = Vpim::encode_paramtext(partstat)
        end

        if rsvp
          params['RSVP'] = 'true'
        end

        Vpim::DirectoryInfo::Field.create(name, value, params)
      end

      # Return true if the +uri+ is == to this address' URI. The comparison
      # is case-insensitive (because email addresses and domain names are).
      def ==(uri)
        # TODO - could I use a URI library?
        Vpim::Methods.casecmp?(self.uri.to_str, uri.to_str)
      end

      # A string representation of an address, using the common name, and the
      # URI. The URI protocol is stripped if it's "mailto:".
      def to_s
        u = uri
        u = u.gsub(/^mailto: */i, '')

        if cn.length > 0
          "#{cn.inspect} <#{uri}>"
        else
          uri
        end
      end

      def inspect #:nodoc:
        "#<Vpim::Icalendar::Address:cn=#{cn.inspect} status=#{partstat} rsvp=#{rsvp} #{uri.inspect}>"
      end

    end
  end
end

