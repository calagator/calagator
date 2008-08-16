=begin
  Copyright (C) 2008 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

require 'enumerator'

require 'plist'

require 'vpim/icalendar'
require 'vpim/duration'

module Vpim
  # A Repo is a representation of a calendar repository.
  #
  # Currently supported repository types are:
  # - Repo::Apple3, an Apple iCal3 repository.
  # - Repo::Directory, a directory hierarchy containing .ics files
  #
  # All repository types support at least the methods of Repo, and all
  # repositories return calendars that support at least the methods of
  # Repo::Calendar.
  class Repo
    include Enumerable

    # Open a repository at location +where+.
    def initialize(where)
    end

    # Enumerate the calendars in the repository.
    def each #:yield: calendar
    end

    # A calendar abstraction. It models a calendar in a calendar repository
    # that may not be an iCalendar.
    #
    # It has methods that behave identically to Icalendar, but it also has
    # methods like name and displayed that are not present in an iCalendar.
    class Calendar
      include Enumerable

      # The calendar name.
      def name
      end

      # Whether a calendar should be displayed.
      #
      # TODO - should be #displayed?
      def displayed
      end

      # Encode into iCalendar format.
      def encode
      end

      # Enumerate the components in the calendar, both todos and events, or
      # the specified klass. Like Icalendar#each()
      def each(klass=nil, &block) #:yield: component
      end

      # Enumerate the events in the calendar.
      def events(&block) #:yield: Vevent
        each(Vpim::Icalendar::Vevent, &block)
      end

      # Enumerate the todos in the calendar.
      def todos(&block) #:yield: Vtodo
        each(Vpim::Icalendar::Vtodo, &block)
      end

      # The method definitions are just to fool rdoc, not to be used.
      %w{each name displayed encode}.each{|m| remove_method m}

      def file_each(file, klass, &block) #:nodoc:
        unless iterator?
          return Enumerable::Enumerator.new(self, :each, klass)
        end

        cals = Vpim::Icalendar.decode(File.open(file))

        cals.each do |cal|
          cal.each(klass, &block)
        end
        self
      end
    end
  end

  class Repo
    include Enumerable

    # An Apple iCal version 3 repository.
    class Apple3 < Repo
      def initialize(where = "~/Library/Calendars")
        @where = where.to_str
      end

      def each #:nodoc:
        Dir[ File.expand_path(@where + "/**/*.calendar") ].each do |dir|
          yield Calendar.new(dir)
        end
        self
      end

      class Calendar < Repo::Calendar
        def initialize(dir) # :nodoc:
          @dir = dir
        end

        def plist(key) #:nodoc:
          Plist::parse_xml( @dir + "/Info.plist")[key]
        end

        def name #:nodoc:
          plist "Title"
        end

        def displayed #:nodoc:
          1 == plist("Checked")
        end

        def each(klass=nil, &block) #:nodoc:
          unless iterator?
            return Enumerable::Enumerator.new(self, :each, klass)
          end
          Dir[ @dir + "/Events/*.ics" ].map do |ics|
            file_each(ics, klass, &block)
          end
          self
        end

        def encode #:nodoc:
          Icalendar.create2 do |cal|
            each{|c| cal << c}
          end.encode
        end
      end

    end

    class Directory < Repo
      class Calendar < Repo::Calendar
        def initialize(file) #:nodoc:
          @file = file
        end

        def name #:nodoc:
          File.basename(@file)
        end

        def displayed #:nodoc:
          true
        end

        def each(klass, &block) #:nodoc:
          file_each(@file, klass, &block)
        end

        def encode #:nodoc:
          open(@file, "r"){|f| f.read}
        end

      end

      def initialize(where = ".")
        @where = where.to_str
      end

      def each #:nodoc:
        Dir[ File.expand_path(@where + "/**/*.ics") ].each do |file|
          yield Calendar.new(file)
        end
        self
      end
    end
  end
end

