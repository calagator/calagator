=begin
  Copyright (C) 2006 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

require 'vpim/address'
require 'vpim/attachment'

module Vpim
  class Icalendar
    module Property

      # Properties common to Vevent, Vtodo, and Vjournal.
      module Common

        # This property defines the access classification for a calendar
        # component.
        #
        # An access classification is only one component of the general
        # security system within a calendar application. It provides a method
        # of capturing the scope of the access the calendar owner intends for
        # information within an individual calendar entry. The access
        # classification of an individual iCalendar component is useful when
        # measured along with the other security components of a calendar
        # system (e.g., calendar user authentication, authorization, access
        # rights, access role, etc.). Hence, the semantics of the individual
        # access classifications cannot be completely defined by this memo
        # alone. Additionally, due to the "blind" nature of most exchange
        # processes using this memo, these access classifications cannot serve
        # as an enforcement statement for a system receiving an iCalendar
        # object.  Rather, they provide a method for capturing the intention of
        # the calendar owner for the access to the calendar component.
        #
        # Property Name: CLASS
        #
        # Property Value: one of "PUBLIC", "PRIVATE", "CONFIDENTIAL", default
        # is "PUBLIC" if no CLASS property is found.
        def access_class
          proptoken 'CLASS', ["PUBLIC", "PRIVATE", "CONFIDENTIAL"], "PUBLIC"
        end

        def created
          proptime 'CREATED'
        end

        # Description of the calendar component, or nil if there is no
        # description.
        def description
          proptext 'DESCRIPTION'
        end

        # Revision sequence number of the calendar component, or nil if there
        # is no SEQUENCE; property.
        def sequence
          propinteger 'SEQUENCE'
        end

        # The time stamp for this calendar component.
        def dtstamp
          proptime 'DTSTAMP'
        end

        # The start time for this calendar component.
        def dtstart
          proptime 'DTSTART'
        end

        def lastmod
          proptime 'LAST-MODIFIED'
        end

        # Return the event organizer, an object of Icalendar::Address (or nil if
        # there is no ORGANIZER field).
        def organizer
          organizer = @properties.field('ORGANIZER')

          if organizer
            organizer = Icalendar::Address.decode(organizer)
          end

          organizer.freeze
        end

=begin
recurid
seq
=end

        # Status values are not rejected during decoding. However, if the
        # status is requested, and it's value is not one of the defined
        # allowable values, an exception is raised.
        def status
          case self
          when Vpim::Icalendar::Vevent
            proptoken 'STATUS', ['TENTATIVE', 'CONFIRMED', 'CANCELLED']

          when Vpim::Icalendar::Vtodo
            proptoken 'STATUS', ['NEEDS-ACTION', 'COMPLETED', 'IN-PROCESS', 'CANCELLED']

          when Vpim::Icalendar::Vevent
            proptoken 'STATUS', ['DRAFT', 'FINAL', 'CANCELLED']
          end
        end

        # TODO - def status? ...

        # TODO - def status= ...

        # Summary description of the calendar component, or nil if there is no
        # SUMMARY property.
        def summary
          proptext 'SUMMARY'
        end

        # The unique identifier of this calendar component, a string.
        def uid
          proptext 'UID'
        end

        def url
          propvalue 'URL'
        end

        # Return an array of attendees, an empty array if there are none. The
        # attendees are objects of Icalendar::Address. If +uri+ is specified
        # only the return the attendees with this +uri+.
        def attendees(uri = nil)
          attendees = @properties.enum_by_name('ATTENDEE').map { |a| Icalendar::Address.decode(a) }
          attendees.freeze
          if uri
            attendees.select { |a| a == uri }
          else
            attendees
          end
        end

        # Return true if the +uri+, usually a mailto: URI, is an attendee.
        def attendee?(uri)
          attendees.include? uri
        end

        # This property defines the categories for a calendar component.
        #
        # Property Name: CATEGORIES
        #
        # Value Type: TEXT
        #
        # Ruby Type: Array of String
        #
        # This property is used to specify categories or subtypes of the
        # calendar component. The categories are useful in searching for a
        # calendar component of a particular type and category.
        def categories
          proptextlistarray 'CATEGORIES'
        end

        def comments
          proptextarray 'COMMENT'
        end

        def contacts
          proptextarray 'CONTACT'
        end

        # An Array of attachments, see Attachment for more information.
        def attachments
          @properties.enum_by_name('ATTACH').map do |f|
            attachment = Attachment.decode(f, 'uri', 'FMTTYPE')
          end
        end
      end

    end

    module Set

      # Properties common to Vevent, Vtodo, and Vjournal.
      module Common

        # Set the access class of the component, see Icalendar::Get::Common#access_class.
        def access_class(token)
          set_token 'CLASS', ["PUBLIC", "PRIVATE", "CONFIDENTIAL"], "PUBLIC", token
        end

        # Set the creation time, see Icalendar::Get::Common#created
        def created(time)
          set_datetime 'CREATED', time
        end

        # Set the description, see Icalendar::Get::Common#description.
        def description(text)
          set_text 'DESCRIPTION', text
        end

        # Set the sequence number, see Icalendar::Get::Common#sequence.
        # is no SEQUENCE; property.
        def sequence(int)
          set_integer 'SEQUENCE', int
        end

        # Set the timestamp, see Icalendar::Get::Common#timestamp.
        def dtstamp(time)
          set_datetime 'DTSTAMP', time
          self
        end

        # The start time or date, see Icalendar::Get::Common#dtstart.
        def dtstart(start)
          set_date_or_datetime 'DTSTART', 'DATE-TIME', start
          self
        end

        # Set the last modification time, see Icalendar::Get::Common#lastmod.
        def lastmod(time)
          set_datetime 'LAST-MODIFIED', time
          self
        end

        # Set the event organizer, an Icalendar::Address, see Icalendar::Get::Common#organizer.
        #
        # Without an +adr+ it yields an Icalendar::Address that is a copy of
        # the current organizer (if any), allowing it to be modified.
        def organizer(adr=nil) #:yield: organizer
          unless adr
            adr = @comp.organizer
            if adr
              adr = adr.copy
            else
              adr = Icalendar::Address.create
            end
            yield adr
          end
          set_address('ORGANIZER', adr)
          self
        end

=begin
        # Status values are not rejected during decoding. However, if the
        # status is requested, and it's value is not one of the defined
        # allowable values, an exception is raised.
        def status
          case self
          when Vpim::Icalendar::Vevent
            proptoken 'STATUS', ['TENTATIVE', 'CONFIRMED', 'CANCELLED']

          when Vpim::Icalendar::Vtodo
            proptoken 'STATUS', ['NEEDS-ACTION', 'COMPLETED', 'IN-PROCESS', 'CANCELLED']

          when Vpim::Icalendar::Vevent
            proptoken 'STATUS', ['DRAFT', 'FINAL', 'CANCELLED']
          end
        end
=end

        # Set summary description of component, see Icalendar::Get::Common#summary.
        def summary(text)
          set_text 'SUMMARY', text
        end

        # Set the unique identifier of this calendar component, see Icalendar::Get::Common#uid.
        def uid(uid)
          set_text 'UID', uid
        end

        def url(url)
          set_text 'URL', url
        end

        # Add an attendee Address, see Icalendar::Get::Common#attendees.
        def add_attendee(adr)
          add_address('ATTENDEE', adr)
        end

        # Set the categories, see Icalendar::Get::Common#attendees.
        #
        # If +cats+ is provided, the categories are set to cats, either a
        # String or an Array of String. Otherwise, and array of the existing
        # category strings is yielded, and it can be modified.
        def categories(cats = nil) #:yield: categories
          unless cats
            cats = @comp.categories
            yield cats
          end
          # TODO - strip the strings
          set_text_list('CATEGORIES', cats)
        end

        # Set the comment, see Icalendar::Get::Common#comment.
        def comment(value)
          set_text 'COMMENT', value
        end

=begin
        def contacts
          proptextarray 'CONTACT'
        end

        # An Array of attachments, see Attachment for more information.
        def attachments
          @properties.enum_by_name('ATTACH').map do |f|
            attachment = Attachment.decode(f, 'uri', 'FMTTYPE')
          end
        end
=end

      end

    end
  end
end


