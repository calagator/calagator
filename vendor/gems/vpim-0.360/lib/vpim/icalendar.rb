=begin
  Copyright (C) 2006 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

require 'vpim/rfc2425'
require 'vpim/dirinfo'
require 'vpim/rrule'
require 'vpim/vevent'
require 'vpim/vtodo'
require 'vpim/vjournal'
require 'vpim/vpim'

module Vpim
  # An iCalendar.
  #
  # A Calendar is some meta-information followed by a sequence of components.
  #
  # Defined components are Event, Todo, Freebusy, Journal, and Timezone, each
  # of which are represented by their own class, though they share many
  # properties in common. For example, Event and Todo may both contain
  # multiple Alarm components.
  #
  # = Reference
  #
  # The iCalendar format is specified by a series of IETF documents:
  #
  # - link:rfc2445.txt: Internet Calendaring and Scheduling Core Object Specification
  # - link:rfc2446.txt: iCalendar Transport-Independent Interoperability Protocol
  #   (iTIP) Scheduling Events, BusyTime, To-dos and Journal Entries
  # - link:rfc2447.txt: iCalendar Message-Based Interoperability Protocol
  #
  # = iCalendar and vCalendar
  #
  # iCalendar files have VERSION:2.0 and vCalendar have VERSION:1.0.  iCalendar
  # (RFC 2445) is based on vCalendar, but but is not very compatible.  While
  # much appears to be similar, the recurrence rule syntax is completely
  # different.
  #
  # iCalendars are usually transmitted in files with <code>.ics</code>
  # extensions.
  class Icalendar
    include Vpim

    # Regular expression strings for the EBNF of RFC 2445
    module Bnf #:nodoc:
      # dur-value = ["+" / "-"] "P" [ 1*DIGIT "W" ] [ 1*DIGIT "D" ] [ "T" [ 1*DIGIT "H" ]  [ 1*DIGIT "M" ] [ 1*DIGIT "S" ] ]
      DURATION = '([-+])?P(\d+W)?(\d+D)?T?(\d+H)?(\d+M)?(\d+S)?'
    end

    private_class_method :new

    # Create a new Icalendar object from +fields+, an array of
    # DirectoryInfo::Field objects.
    #
    # When decoding Calendar data, you would usually use Icalendar.decode(),
    # which decodes the data into the field arrays, and calls this method
    # for each Calendar it finds.
    def initialize(fields) #:nodoc:
      # seperate into the outer-level fields, and the arrays of component
      # fields
      outer, inner = Vpim.outer_inner(fields)

      # Make a dirinfo out of outer, and check its an iCalendar
      @properties = DirectoryInfo.create(outer)
      @properties.check_begin_end('VCALENDAR')

      @components = []

      factory = {
        'VEVENT' => Vevent,
        'VTODO' => Vtodo,
        'VJOURNAL' => Vjournal,
      }

      inner.each do |component|
        name = component.first
        unless name.name? 'BEGIN'
          raise InvalidEncodingError, "calendar component begins with #{name.name}, instead of BEGIN!"
        end

        name = name.value

        if klass = factory[name]
          @components << klass.new(component)
        end
      end
    end

    # Add and event to this calendar.
    #
    # Yields an event maker, Icalendar::Vevent::Maker.
    def add_event(&block) #:yield:event
      push Vevent::Maker.make( &block )
    end

    # FIXME - could take mandatory fields as an arguments
    # FIXME - args: support PRODID
    # FIXME - yield an Icalendar::Maker if block provided
    # FIXME - maker#prodid=
    def Icalendar.create2(args = nil)
      # FIXME - make the primary API
      di = DirectoryInfo.create( [ DirectoryInfo::Field.create('VERSION', '2.0') ], 'VCALENDAR' )

      di.push_unique DirectoryInfo::Field.create('PRODID',   Vpim::PRODID)
      di.push_unique DirectoryInfo::Field.create('CALSCALE', "Gregorian")

      new(di.to_a)
    end

    # Create a new Icalendar object with the minimal set of fields for a valid
    # Calendar. If specified, +fields+ must be an array of
    # DirectoryInfo::Field objects to add. They can override the the default
    # Calendar fields, so, for example, this can be used to set a custom PRODID field.
    def Icalendar.create(fields=[])
      di = DirectoryInfo.create( [ DirectoryInfo::Field.create('VERSION', '2.0') ], 'VCALENDAR' )

      DirectoryInfo::Field.create_array(fields).each { |f| di.push_unique f }

      di.push_unique DirectoryInfo::Field.create('PRODID',   Vpim::PRODID)
      di.push_unique DirectoryInfo::Field.create('CALSCALE', "Gregorian")

      new(di.to_a)
    end

    # Create a new Icalendar object with a protocol method of REPLY.
    #
    # Meeting requests, and such, are Calendar containers with a protocol
    # method of REQUEST, and contains some number of Events, Todos, etc.,
    # that may need replying to. In order to reply to any of these components
    # of a request, you must first build a Calendar object to hold your reply
    # components.
    #
    # This method builds the reply Calendar, you then will add to it replies
    # to the specific components of the request Calendar that you are replying
    # to. If you have any particular fields that you want to be in the
    # Calendar, other than the defaults, then can be supplied as +fields+, an
    # array of Field objects.
    def Icalendar.create_reply(fields=[])
      fields << DirectoryInfo::Field.create('METHOD', 'REPLY')

      Icalendar.create(fields)
    end

    # Used during encoding.
    def fields # :nodoc:
      f = @properties.to_a
      last = f.pop
      @components.each { |c| f << c.fields }
      f.push last
    end

    # Encode the Calendar as a string. The width is the maximum width of the
    # encoded lines, it can be specified, but is better left to the default.
    def encode(width=nil)
      # We concatenate the fields of all objects, create a DirInfo, then
      # encode it.
      di = DirectoryInfo.create(self.fields.flatten)
      di.encode(width)
    end

    alias to_s encode

    # Push a calendar component onto the calendar.
    def push(component)
      case component
        when Vevent, Vtodo, Vjournal
          @components << component
        else
          raise ArgumentError, "can't add a #{component.type} to a calendar"
      end
      self
    end

    # Check if the protocol method is +method+
    def protocol?(method)
      Vpim::Methods.casecmp?(protocol, method)
    end

    def Icalendar.decode_duration(str) #:nodoc:
      unless match = %r{\s*#{Bnf::DURATION}\s*}.match(str)
        raise InvalidEncodingError, "duration not valid (#{str})"
      end
      dur = 0

      # Remember: match[0] is the whole match string, match[1] is $1, etc.

      # Week
      if match[2]
        dur = match[2].to_i
      end
      # Days
      dur *= 7
      if match[3]
        dur += match[3].to_i
      end
      # Hours
      dur *= 24
      if match[4]
        dur += match[4].to_i
      end
      # Minutes
      dur *= 60
      if match[5]
        dur += match[5].to_i
      end
      # Seconds
      dur *= 60
      if match[6]
        dur += match[6].to_i
      end

      if match[1] && match[1] == '-'
        dur = -dur
      end

      dur
    end

    # Decode iCalendar data into an array of Icalendar objects.
    #
    # Since iCalendars are self-delimited (by a BEGIN:VCALENDAR and an
    # END:VCALENDAR), multiple iCalendars can be concatenated into a single
    # file.
    #
    # cal must be String or IO, or implement #each by returning
    # each line in the input as those classes do.
    def Icalendar.decode(cal, e = nil)
      entities = Vpim.expand(Vpim.decode(cal))

      # Since all iCalendars must have a begin/end, the top-level should
      # consist entirely of entities/arrays, even if its a single iCalendar.
      if entities.detect { |e| ! e.kind_of? Array }
        raise "Not a valid iCalendar"
      end

      calendars = []

      entities.each do |e|
        calendars << new(e)
      end

      calendars
    end

    # The iCalendar version multiplied by 10 as an Integer.  If no VERSION field
    # is present (which is non-conformant), nil is returned. iCalendar must
    # have a version of 20, and vCalendar would have a version of 10.
    def version
      v = @properties['VERSION']

      unless v
        raise InvalidEncodingError, "Invalid calendar, no version field!"
      end

      v = v.to_f * 10
      v = v.to_i
    end

    # The value of the PRODID field, an unstructured string meant to
    # identify the software which encoded the Calendar data.
    def producer
      #f = @properties.field('PRODID')
      #f && f.to_text
      @properties.text('PRODID').first
    end

    # The value of the METHOD field. Protocol methods are used when iCalendars
    # are exchanged in a calendar messaging system, such as iTIP or iMIP. When
    # METHOD is not specified, the Calendar object is merely being used to
    # transport a snapshot of some calendar information; without the intention
    # of conveying a scheduling semantic.
    #
    # Note that this method can't be called +method+, thats already a method of
    # Object.
    def protocol
      m = @properties['METHOD']
      m ? m.upcase : m
    end

    # The value of the CALSCALE: property, or "GREGORIAN" if CALSCALE: is not
    # present.
    #
    # This is of academic interest, really because there aren't any other
    # calendar scales defined, and given that its hard enough just dealing with
    # Gregorian calendars, there probably won't be.
    def calscale
      proptext('CALSCALE') || 'GREGORIAN'
    end

    # The array of all supported calendar components. If a class is provided,
    # return only the components of that class.
    #
    # If a block is provided, yield the components instead of returning them.
    #
    # Examples:
    #   calendar.components(Vpim::Icalendar::Vevent)
    #   => array of all calendar components
    #
    #   calendar.components(Vpim::Icalendar::Vtodo) {|c| c... }
    #   => yield all todo components
    #
    #   calendar.components {|c| c... }
    #   => yield all components
    def components(klass=Object) #:yields:component
      # TODO - should this take an interval: t0,t1?

      unless block_given?
        return @components.select{|c| klass === c}.freeze
      end

      @components.each do |c|
        if klass === c
          yield c
        end
      end
      self
    end

    # For backwards compatibility. Use #components.
    def events #:nodoc:
      components Icalendar::Vevent
    end

    # For backwards compatibility. Use #components.
    def todos #:nodoc:
      components Icalendar::Vtodo
    end

  end

end

