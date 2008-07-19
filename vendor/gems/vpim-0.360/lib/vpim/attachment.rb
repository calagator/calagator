=begin
  Copyright (C) 2006 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

require 'vpim/icalendar'

module Vpim

  # Attachments are used by both iCalendar and vCard. They are either a URI or
  # inline data, and their decoded value will be either a Uri or a Inline, as
  # appropriate.
  #
  # Besides the methods specific to their class, both kinds of object implement
  # a set of common methods, allowing them to be treated uniformly:
  # - Uri#to_io, Inline#to_io: return an IO from which the value can be read.
  # - Uri#to_s, Inline#to_s: return the value as a String.
  # - Uri#format, Inline#format: the format of the value. This is supposed to
  #   be an "iana defined" identifier (like "image/jpeg"), but could be almost
  #   anything (or nothing) in practice.  Since the parameter is optional, it may
  #   be "".
  #
  # The objects can also be distinguished by their class, if necessary.
  module Attachment

    # TODO - It might be possible to autodetect the format from the first few
    # bytes of the value, and return the appropriate MIME type when format
    # isn't defined.
    #
    # iCalendar and vCard put the format in different parameters, and the
    # default kind of value is different.
    def Attachment.decode(field, defkind, fmtparam) #:nodoc:
      format = field.pvalue(fmtparam) || ''
      kind = field.kind || defkind
      case kind
      when 'text'
        Inline.new(Vpim.decode_text(field.value), format)
      when 'uri'
        Uri.new(field.value_raw, format)
      when 'binary'
        Inline.new(field.value, format)
      else
        raise InvalidEncodingError, "Attachment of type #{kind} is not allowed"
      end
    end

    # Extends a String to support some of the same methods as Uri.
    class Inline < String
      def initialize(s, format) #:nodoc:
        @format = format
        super(s)
      end

      # Return an IO object for the inline data. See +stringio+ for more
      # information.
      def to_io
        StringIO.new(self)
      end

      # The format of the inline data.
      # See Attachment.
      attr_reader :format
    end

    # Encapsulates a URI and implements some methods of String.
    class Uri
      def initialize(uri, format) #:nodoc:
        @uri = uri
        @format = format
      end

      # The URI value.
      attr_reader :uri

      # The format of the data referred to by the URI.
      # See Attachment.
      attr_reader :format

      # Return an IO object from opening the URI.  See +open-uri+ for more
      # information.
      def to_io
        open(@uri)
      end

      # Return the String from reading the IO object to end-of-data.
      def to_s
        to_io.read(nil)
      end

      def inspect #:nodoc:
        s = "<#{self.class.to_s}: #{uri.inspect}>"
        s << ", #{@format.inspect}" if @format
        s
      end
    end

  end
end

