=begin
  Copyright (C) 2008 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

require 'vpim/enumerator'
require 'vpim/field'
require 'vpim/rfc2425'
require 'vpim/vpim'

module Vpim
  # An RFC 2425 directory info object.
  #
  # A directory information object is a sequence of fields. The basic
  # structure of the object, and the way in which it is broken into fields
  # is common to all profiles of the directory info type.
  #
  # A vCard, for example, is a specialization of a directory info object.
  #
  # - [RFC2425] the directory information framework (ftp://ftp.ietf.org/rfc/rfc2425.txt)
  #
  # Here's an example of encoding a simple vCard using the low-level APIs:
  #
  #   card = Vpim::Vcard.create
  #   card << Vpim::DirectoryInfo::Field.create('EMAIL', 'user.name@example.com', 'TYPE' => 'INTERNET' )
  #   card << Vpim::DirectoryInfo::Field.create('URL', 'http://www.example.com/user' )
  #   card << Vpim::DirectoryInfo::Field.create('FN', 'User Name' )
  #   puts card.to_s
  #
  # Don't do it like that, use Vpim::Vcard::Maker.
  class DirectoryInfo
    include Enumerable

    private_class_method :new

    # Initialize a DirectoryInfo object from +fields+. If +profile+ is
    # specified, check the BEGIN/END fields.
    def initialize(fields, profile = nil) #:nodoc:
      if fields.detect { |f| ! f.kind_of? DirectoryInfo::Field }
        raise ArgumentError, 'fields must be an array of DirectoryInfo::Field objects'
      end

      @string = nil # this is used as a flag to indicate that recoding will be necessary
      @fields = fields

      check_begin_end(profile) if profile
    end

    # Decode +card+ into a DirectoryInfo object.
    #
    # +card+ may either be a something that is convertible to a string using
    # #to_str or an Array of objects that can be joined into a string using
    # #join("\n"), or an IO object (which will be read to end-of-file).
    #
    # The lines in the string may be delimited using IETF (CRLF) or Unix (LF) conventions.
    #
    # A DirectoryInfo is mutable, you can add new fields to it, see
    # Vpim::DirectoryInfo::Field#create() for how to create a new Field.
    #
    # TODO: I don't believe this is ever used, maybe I can remove it.
    def DirectoryInfo.decode(card) #:nodoc:
      if card.respond_to? :to_str
        string = card.to_str
      elsif card.kind_of? Array
        string = card.join("\n")
      elsif card.kind_of? IO
        string = card.read(nil)
      else
        raise ArgumentError, "DirectoryInfo cannot be created from a #{card.type}"
      end

      fields = Vpim.decode(string)

      new(fields)
    end

    # Create a new DirectoryInfo object. The +fields+ are an optional array of
    # DirectoryInfo::Field objects to add to the new object, between the
    # BEGIN/END.  If the +profile+ string is not nil, then it is the name of
    # the directory info profile, and the BEGIN:+profile+/END:+profile+ fields
    # will be added.
    #
    # A DirectoryInfo is mutable, you can add new fields to it using #push(),
    # and see Field#create().
    def DirectoryInfo.create(fields = [], profile = nil)

      if profile
        p = profile.to_str
        f = [ Field.create('BEGIN', p) ]
        f.concat fields
        f.push Field.create('END', p)
        fields = f
      end
      
      new(fields, profile)
    end

    # The first field named +name+, or nil if no
    # match is found.
    def field(name)
      enum_by_name(name).each { |f| return f }
      nil
    end

    # The value of the first field named +name+, or nil if no
    # match is found.
    def [](name)
      enum_by_name(name).each { |f| return f.value if f.value != ''}
      enum_by_name(name).each { |f| return f.value }
      nil
    end

    # An array of all the values of fields named +name+, converted to text
    # (using Field#to_text()).
    #
    # TODO - call this #texts(), as in the plural?
    def text(name)
      accum = []
      each do |f|
        if f.name? name
          accum << f.to_text
        end
      end
      accum
    end

    # Array of all the Field#group()s.
    def groups
      @fields.collect { |f| f.group } .compact.uniq
    end

    # All fields, frozen.
    def fields #:nodoc:
      @fields.dup.freeze
    end

    # Yields for each Field for which +cond+.call(field) is true. The
    # (default) +cond+ of nil is considered true for all fields, so
    # this acts like a normal #each() when called with no arguments.
    def each(cond = nil) # :yields: Field
      @fields.each do |field|
         if(cond == nil || cond.call(field))
           yield field
         end
      end
      self
    end

    # Returns an Enumerator for each Field for which #name?(+name+) is true.
    #
    # An Enumerator supports all the methods of Enumerable, so it allows iteration,
    # collection, mapping, etc.
    #
    # Examples:
    #
    # Print all the nicknames in a card:
    #  
    #   card.enum_by_name('NICKNAME') { |f| puts f.value }
    #
    # Print an Array of the preferred email addresses in the card:
    #
    #   pref_emails = card.enum_by_name('EMAIL').select { |f| f.pref? }
    def enum_by_name(name)
      Enumerator.new(self, Proc.new { |field| field.name?(name) })
    end

    # Returns an Enumerator for each Field for which #group?(+group+) is true.
    #
    # For example, to print all the fields, sorted by group, you could do:
    #
    #   card.groups.sort.each do |group|
    #     card.enum_by_group(group).each do |field|
    #       puts "#{group} -> #{field.name}"
    #     end
    #   end
    #
    # or to get an array of all the fields in group 'AGROUP', you could do:
    # 
    #   card.enum_by_group('AGROUP').to_a
    def enum_by_group(group)
      Enumerator.new(self, Proc.new { |field| field.group?(group) })
    end

    # Returns an Enumerator for each Field for which +cond+.call(field) is true.
    def enum_by_cond(cond)
      Enumerator.new(self, cond )
    end

    # Force card to be reencoded from the fields.
    def dirty #:nodoc:
      #string = nil
    end

    # Append +field+ to the fields. Note that it won't be literally appended
    # to the fields, it will be inserted before the closing END field.
    def push(field)
      dirty
      @fields[-1,0] = field
      self
    end

    alias << push

    # Push +field+ onto the fields, unless there is already a field
    # with this name.
    def push_unique(field)
      push(field) unless @fields.detect { |f| f.name? field.name }
      self
    end

    # Append +field+ to the end of all the fields. This isn't usually what you
    # want to do, usually a DirectoryInfo's first and last fields are a
    # BEGIN/END pair, see #push().
    def push_end(field)
      @fields << field
      self
    end

    # Delete +field+.
    #
    # Warning: You can't delete BEGIN: or END: fields, but other
    # profile-specific fields can be deleted, including mandatory ones. For
    # vCards in particular, in order to avoid destroying them, I suggest
    # creating a new Vcard, and copying over all the fields that you still
    # want, rather than using #delete. This is easy with Vcard::Maker#copy, see
    # the Vcard::Maker examples.
    def delete(field)
      case
      when field.name?('BEGIN'), field.name?('END')
        raise ArgumentError, 'Cannot delete BEGIN or END fields.'
      else
        @fields.delete field
      end

      self
    end

    # The string encoding of the DirectoryInfo. See Field#encode for information
    # about the width parameter.
    def encode(width=nil)
      unless @string
        @string = @fields.collect { |f| f.encode(width) } . join ""
      end
      @string
    end

    alias to_s encode

    # Check that the DirectoryInfo object is correctly delimited by a BEGIN
    # and END, that their profile values match, and if +profile+ is specified, that 
    # they are the specified profile.
    def check_begin_end(profile=nil) #:nodoc:
      unless @fields.first
        raise "No fields to check"
      end
      unless @fields.first.name? 'BEGIN'
        raise "Needs BEGIN, found: #{@fields.first.encode nil}"
      end
      unless @fields.last.name? 'END'
        raise "Needs END, found: #{@fields.last.encode nil}"
      end
      unless @fields.last.value? @fields.first.value
        raise "BEGIN/END mismatch: (#{@fields.first.value} != #{@fields.last.value}"
      end
      if profile
        if ! @fields.first.value? profile
          raise "Mismatched profile"
        end
      end
      true
    end
  end
end

