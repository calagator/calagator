=begin
  Copyright (C) 2006 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

require 'vpim/vpim'
require 'vpim/attachment'
require 'vpim/dirinfo'

require 'open-uri'
require 'stringio'

module Vpim
  # A vCard, a specialization of a directory info object.
  #
  # The vCard format is specified by:
  # - RFC2426: vCard MIME Directory Profile (vCard 3.0)
  # - RFC2425: A MIME Content-Type for Directory Information
  #
  # This implements vCard 3.0, but it is also capable of working with vCard 2.1
  # if used with care.
  #
  # All line values can be accessed with Vcard#value, Vcard#values, or even by
  # iterating through Vcard#lines. Line types that don't have specific support
  # and non-standard line types ("X-MY-SPECIAL", for example) will be returned
  # as a String, with any base64 or quoted-printable encoding removed. 
  #
  # Specific support exists to return more useful values for the standard vCard
  # types, where appropriate.
  #
  # The wrapper functions (#birthday, #nicknames, #emails, etc.) exist
  # partially as an API convenience, and partially as a place to document
  # the values returned for the more complex types, like PHOTO and EMAIL.
  #
  # For types that do not sensibly occur multiple times (like BDAY or GEO),
  # sometimes a wrapper exists only to return a single line, using #value.
  # However, if you find the need, you can still call #values to get all the
  # lines, and both the singular and plural forms will eventually be
  # implemented.
  #
  # If there is sufficient demand, specific support for vCard 2.1 could be
  # implemented.
  #
  # For more information see:
  # - link:rfc2426.txt: vCard MIME Directory Profile (vCard 3.0)
  # - link:rfc2425.txt: A MIME Content-Type for Directory Information
  # - http://www.imc.org/pdi/pdiproddev.html: vCard 2.1 Specifications
  #
  # vCards are usually transmitted in files with <code>.vcf</code>
  # extensions.
  #
  # = Examples
  #
  # - link:ex_mkvcard.txt: example of creating a vCard
  # - link:ex_cpvcard.txt: example of copying and them modifying a vCard
  # - link:ex_mkv21vcard.txt: example of creating version 2.1 vCard
  # - link:mutt-aliases-to-vcf.txt: convert a mutt aliases file to vCards
  # - link:ex_get_vcard_photo.txt: pull photo data from a vCard
  # - link:ab-query.txt: query the OS X Address Book to find vCards
  # - link:vcf-to-mutt.txt: query vCards for matches, output in formats useful
  #   with Mutt (see link:README.mutt for details)
  # - link:tabbed-file-to-vcf.txt: convert a tab-delimited file to vCards, a
  #   (small but) complete application contributed by Dane G. Avilla, thanks!
  # - link:vcf-to-ics.txt: example of how to create calendars of birthdays from vCards
  # - link:vcf-dump.txt: utility for dumping contents of .vcf files
  class Vcard < DirectoryInfo

    # Represents the value of an ADR field.
    #
    # #location, #preferred, and #delivery indicate information about how the
    # address is to be used, the other attributes are parts of the address.
    #
    # Using values other than those defined for #location or #delivery is
    # unlikely to be portable, or even conformant.
    #
    # All attributes are optional. #location and #delivery can be set to arrays
    # of strings.
    class Address
      # post office box (String)
      attr_accessor :pobox
      # seldom used, its not clear what it is for (String)
      attr_accessor :extended
      # street address (String)
      attr_accessor :street
      # usually the city (String)
      attr_accessor :locality
      # usually the province or state (String)
      attr_accessor :region
      # postal code (String)
      attr_accessor :postalcode
      # country name (String)
      attr_accessor :country
      # home, work (Array of String): the location referred to by the address
      attr_accessor :location
      # true, false (boolean): where this is the preferred address (for this location)
      attr_accessor :preferred
      # postal, parcel, dom (domestic), intl (international) (Array of String): delivery
      # type of this address
      attr_accessor :delivery

      # nonstandard types, their meaning is undefined (Array of String). These
      # might be found during decoding, but shouldn't be set during encoding.
      attr_reader :nonstandard

      # Used to simplify some long and tedious code. These symbols are in the
      # order required for the ADR field structured TEXT value, the order
      # cannot be changed.
      @@adr_parts = [
        :@pobox,
        :@extended,
        :@street,
        :@locality,
        :@region,
        :@postalcode,
        :@country,
      ]

      # TODO
      # - #location?
      # - #delivery?
      def initialize #:nodoc:
        # TODO - Add #label to support LABEL. Try to find LABEL
        # in either same group, or with sam params.
        @@adr_parts.each do |part|
          instance_variable_set(part, '')
        end

        @location = []
        @preferred = false
        @delivery = []
        @nonstandard = []
      end

      def encode #:nodoc:
        parts = @@adr_parts.map do |part|
          instance_variable_get(part)
        end

        value = Vpim.encode_text_list(parts, ";")

        params = [ @location, @delivery, @nonstandard ]
        params << 'pref' if @preferred
        params = params.flatten.compact.map { |s| s.to_str.downcase }.uniq

        paramshash = {}

        paramshash['TYPE'] = params if params.first

        Vpim::DirectoryInfo::Field.create( 'ADR', value, paramshash)
      end

      def Address.decode(card, field) #:nodoc:
        adr = new

        parts = Vpim.decode_text_list(field.value_raw, ';')

        @@adr_parts.each_with_index do |part,i|
          adr.instance_variable_set(part, parts[i] || '')
        end

        params = field.pvalues('TYPE')

        if params
          params.each do |p|
            p.downcase!
            case p
            when 'home', 'work'
              adr.location << p
            when 'postal', 'parcel', 'dom', 'intl'
              adr.delivery << p
            when 'pref'
              adr.preferred = true
            else
              adr.nonstandard << p
            end
          end
          # Strip duplicates
          [ adr.location, adr.delivery, adr.nonstandard ].each do |a|
            a.uniq!
          end
        end

        adr
      end
    end

    # Represents the value of an EMAIL field.
    class Email < String
      # true, false (boolean): whether this is the preferred email address
      attr_accessor :preferred
      # internet, x400 (String): the email address format, rarely specified
      # since the default is 'internet'
      attr_accessor :format
      # home, work (Array of String): the location referred to by the address. The
      # inclusion of location parameters in a vCard seems to be non-conformant,
      # strictly speaking, but also seems to be widespread.
      attr_accessor :location
      # nonstandard types, their meaning is undefined (Array of String). These
      # might be found during decoding, but shouldn't be set during encoding.
      attr_reader :nonstandard

      def initialize(email='') #:nodoc:
        @preferred = false
        @format = 'internet'
        @location = []
        @nonstandard = []
        super(email)
      end

      def inspect #:nodoc:
        s = "#<#{self.class.to_s}: #{to_str.inspect}"
        s << ", pref" if preferred
        s << ", #{format}" if format != 'internet'
        s << ", " << @location.join(", ") if @location.first
        s << ", #{@nonstandard.join(", ")}" if @nonstandard.first
        s
      end

      def encode #:nodoc:
        value = to_str.strip

        if value.length < 1
          raise InvalidEncodingError, "EMAIL must have a value"
        end

        params = [ @location, @nonstandard ]
        params << @format if @format != 'internet'
        params << 'pref'  if @preferred

        params = params.flatten.compact.map { |s| s.to_str.downcase }.uniq

        paramshash = {}

        paramshash['TYPE'] = params if params.first

        Vpim::DirectoryInfo::Field.create( 'EMAIL', value, paramshash)
      end

      def Email.decode(field) #:nodoc:
        value = field.to_text.strip

        if value.length < 1
          raise InvalidEncodingError, "EMAIL must have a value"
        end

        eml = Email.new(value)

        params = field.pvalues('TYPE')

        if params
          params.each do |p|
            p.downcase!
            case p
            when 'home', 'work'
              eml.location << p
            when 'pref'
              eml.preferred = true
            when 'x400', 'internet'
              eml.format = p
            else
              eml.nonstandard << p
            end
          end
          # Strip duplicates
          [ eml.location, eml.nonstandard ].each do |a|
            a.uniq!
          end
        end

        eml
      end
    end

    # Represents the value of a TEL field.
    # 
    # The value is supposed to be a "X.500 Telephone Number" according to RFC
    # 2426, but that standard is not freely available. Otherwise, anything that
    # looks like a phone number should be OK.
    class Telephone < String
      # true, false (boolean): whether this is the preferred email address
      attr_accessor :preferred
      # home, work, cell, car, pager (Array of String): the location
      # of the device
      attr_accessor :location
      # voice, fax, video, msg, bbs, modem, isdn, pcs (Array of String): the
      # capabilities of the device
      attr_accessor :capability
      # nonstandard types, their meaning is undefined (Array of String). These
      # might be found during decoding, but shouldn't be set during encoding.
      attr_reader :nonstandard

      def initialize(telephone='') #:nodoc:
        @preferred = false
        @location = []
        @capability = []
        @nonstandard = []
        super(telephone)
      end

      def inspect #:nodoc:
        s = "#<#{self.class.to_s}: #{to_str.inspect}"
        s << ", pref" if preferred
        s << ", " << @location.join(", ") if @location.first
        s << ", " << @capability.join(", ") if @capability.first
        s << ", #{@nonstandard.join(", ")}" if @nonstandard.first
        s
      end

      def encode #:nodoc:
        value = to_str.strip

        if value.length < 1
          raise InvalidEncodingError, "TEL must have a value"
        end

        params = [ @location, @capability, @nonstandard ]
        params << 'pref'  if @preferred

        params = params.flatten.compact.map { |s| s.to_str.downcase }.uniq

        paramshash = {}

        paramshash['TYPE'] = params if params.first

        Vpim::DirectoryInfo::Field.create( 'TEL', value, paramshash)
      end

      def Telephone.decode(field) #:nodoc:
        value = field.to_text.strip

        if value.length < 1
          raise InvalidEncodingError, "TEL must have a value"
        end

        tel = Telephone.new(value)

        params = field.pvalues('TYPE')

        if params
          params.each do |p|
            p.downcase!
            case p
            when 'home', 'work', 'cell', 'car', 'pager'
              tel.location << p
            when 'voice', 'fax', 'video', 'msg', 'bbs', 'modem', 'isdn', 'pcs'
              tel.capability << p
            when 'pref'
              tel.preferred = true
            else
              tel.nonstandard << p
            end
          end
          # Strip duplicates
          [ tel.location, tel.capability, tel.nonstandard ].each do |a|
            a.uniq!
          end
        end

        tel
      end
    end

    # The name from a vCard, including all the components of the N: and FN:
    # fields.
    class Name
      # family name, from N
      attr_accessor :family
      # given name, from N
      attr_accessor :given
      # additional names, from N
      attr_accessor :additional
      # such as "Ms." or "Dr.", from N
      attr_accessor :prefix
      # such as "BFA", from N
      attr_accessor :suffix
      # full name, the FN field. FN is a formatted version of the N field,
      # intended to be in a form more aligned with the cultural conventions of
      # the vCard owner than +formatted+ is.
      attr_accessor :fullname
      # all the components of N formtted as "#{prefix} #{given} #{additional} #{family}, #{suffix}"
      attr_reader   :formatted

      # Override the attr reader to make it dynamic
      remove_method :formatted
      def formatted #:nodoc:
        f = [ @prefix, @given, @additional, @family ].map{|i| i == '' ? nil : i.strip}.compact.join(' ')
        if @suffix != ''
          f << ', ' << @suffix
        end
        f
      end

      def initialize(n='', fn='') #:nodoc:
        n = Vpim.decode_text_list(n, ';') do |item|
          item.strip
        end

        @family     = n[0] || ""
        @given      = n[1] || ""
        @additional = n[2] || ""
        @prefix     = n[3] || ""
        @suffix     = n[4] || ""

        # FIXME - make calls to #fullname fail if fn is nil
        @fullname = (fn || "").strip
      end

      def encode #:nodoc:
         Vpim::DirectoryInfo::Field.create('N',
           Vpim.encode_text_list([ @family, @given, @additional, @prefix, @suffix ].map{|n| n.strip}, ';')
           )
      end
      def encode_fn #:nodoc:
        fn = @fullname.strip
        if @fullname.length == 0
          fn = formatted
        end
        Vpim::DirectoryInfo::Field.create('FN', fn)
      end

    end

    def decode_invisible(field) #:nodoc:
      nil
    end

    def decode_default(field) #:nodoc:
      Line.new( field.group, field.name, field.value )
    end

    def decode_version(field) #:nodoc:
      Line.new( field.group, field.name, (field.value.to_f * 10).to_i )
    end

    def decode_text(field) #:nodoc:
      Line.new( field.group, field.name, Vpim.decode_text(field.value_raw) )
    end

    def decode_n(field) #:nodoc:
      Line.new( field.group, field.name, Name.new(field.value, self['FN']).freeze )
    end

    def decode_date_or_datetime(field) #:nodoc:
      date = nil
      begin
        date = Vpim.decode_date(field.value_raw)
        date = Date.new(*date)
      rescue Vpim::InvalidEncodingError
        # FIXME - try and decode as DATE-TIME
        raise
      end
      Line.new( field.group, field.name, date )
    end

    def decode_bday(field) #:nodoc:
      begin
        return decode_date_or_datetime(field)

      rescue Vpim::InvalidEncodingError
        if field.value =~ /(\d+)-(\d+)-(\d+)/
          y = $1.to_i
          m = $2.to_i
          d = $3.to_i
          if(y < 1900)
            y = Time.now.year
          end
          Line.new( field.group, field.name, Date.new(y, m, d) )
        else
          raise
        end
      end
    end

    def decode_geo(field) #:nodoc:
      geo = Vpim.decode_list(field.value_raw, ';') do |item| item.to_f end
      Line.new( field.group, field.name, geo )
    end

    def decode_address(field) #:nodoc:
      Line.new( field.group, field.name, Address.decode(self, field) )
    end

    def decode_email(field) #:nodoc:
      Line.new( field.group, field.name, Email.decode(field) )
    end

    def decode_telephone(field) #:nodoc:
      Line.new( field.group, field.name, Telephone.decode(field) )
    end

    def decode_list_of_text(field) #:nodoc:
      Line.new( field.group, field.name,
               Vpim.decode_text_list(field.value_raw).select{|t| t.length > 0}.uniq
              )
    end

    def decode_structured_text(field) #:nodoc:
      Line.new( field.group, field.name, Vpim.decode_text_list(field.value_raw, ';') )
    end

    def decode_uri(field) #:nodoc:
      Line.new( field.group, field.name, Uri.new(field.value) )
    end

    def decode_agent(field) #:nodoc:
      case field.kind
      when 'text'
        decode_text(field)
      when 'uri'
        decode_uri(field)
      when 'vcard', nil
        Line.new( field.group, field.name, Vcard.decode(Vpim.decode_text(field.value_raw)).first )
      else
        raise InvalidEncodingError, "AGENT type #{field.kind} is not allowed"
      end
    end

    def decode_attachment(field) #:nodoc:
      Line.new( field.group, field.name, Attachment.decode(field, 'binary', 'TYPE') )
    end

    @@decode = {
      'BEGIN'      => :decode_invisible, # Don't return delimiter
      'END'        => :decode_invisible, # Don't return delimiter
      'FN'         => :decode_invisible, # Returned as part of N.

      'ADR'        => :decode_address,
      'AGENT'      => :decode_agent,
      'BDAY'       => :decode_bday,
      'CATEGORIES' => :decode_list_of_text,
      'EMAIL'      => :decode_email,
      'GEO'        => :decode_geo,
      'KEY'        => :decode_attachment,
      'LOGO'       => :decode_attachment,
      'MAILER'     => :decode_text,
      'N'          => :decode_n,
      'NAME'       => :decode_text,
      'NICKNAME'   => :decode_list_of_text,
      'NOTE'       => :decode_text,
      'ORG'        => :decode_structured_text,
      'PHOTO'      => :decode_attachment,
      'PRODID'     => :decode_text,
      'PROFILE'    => :decode_text,
      'REV'        => :decode_date_or_datetime,
      'ROLE'       => :decode_text,
      'SOUND'      => :decode_attachment,
      'SOURCE'     => :decode_text,
      'TEL'        => :decode_telephone,
      'TITLE'      => :decode_text,
      'UID'        => :decode_text,
      'URL'        => :decode_uri,
      'VERSION'    => :decode_version,
    }

    @@decode.default = :decode_default

    # Cache of decoded lines/fields, so we don't have to decode a field more than once.
    attr_reader :cache #:nodoc:

    # An entry in a vCard. The #value object's type varies with the kind of
    # line (the #name), and on how the line was encoded. The objects returned
    # for a specific kind of line are often extended so that they support a
    # common set of methods. The goal is to allow all types of objects for a
    # kind of line to be treated with some uniformity, but still allow specific
    # handling for the various value types if desired.
    #
    # See the specific methods for details.
    class Line
      attr_reader :group
      attr_reader :name
      attr_reader :value

      def initialize(group, name, value) #:nodoc:
        @group, @name, @value = (group||''), name.to_str, value
      end

      def self.decode(decode, card, field) #:nodoc:
        card.cache[field] || (card.cache[field] = card.send(decode[field.name], field))
      end
    end

    #@lines = {} FIXME - dead code

    # Return line for a field
    def f2l(field) #:nodoc:
      Line.decode(@@decode, self, field)
    end

    # With no block, returns an Array of Line. If +name+ is specified, the
    # Array will only contain the +Line+s with that +name+. The Array may be
    # empty.
    #
    # If a block is given, each Line will be yielded instead of being returned
    # in an Array.
    def lines(name=nil) #:yield: Line
      # FIXME - this would be much easier if #lines was #each, and there was a
      # different #lines that returned an Enumerator that used #each
      unless block_given?
        map do |f|
          if( !name || f.name?(name) )
           f2l(f)
          else
            nil
          end
        end.compact
      else
        each do |f|
          if( !name || f.name?(name) )
            line = f2l(f)
            if line
              yield line
            end
          end
        end
        self
      end
    end

    private_class_method :new

    def initialize(fields, profile) #:nodoc:
      @cache = {}
      super(fields, profile)
    end

    # Create a vCard 3.0 object with the minimum required fields, plus any
    # +fields+ you want in the card (they can also be added later).
    def Vcard.create(fields = [] )
      fields.unshift Field.create('VERSION', "3.0")
      super(fields, 'VCARD')
    end

    # Decode a collection of vCards into an array of Vcard objects.
    #
    # +card+ can be either a String or an IO object.
    #
    # Since vCards are self-delimited (by a BEGIN:vCard and an END:vCard),
    # multiple vCards can be concatenated into a single directory info object.
    # They may or may not be related. For example, AddressBook.app (the OS X
    # contact manager) will export multiple selected cards in this format.
    #
    # Input data will be converted from unicode if it is detected. The heuristic
    # is based on the first bytes in the string:
    # - 0xEF 0xBB 0xBF: UTF-8 with a BOM, the BOM is stripped
    # - 0xFE 0xFF: UTF-16 with a BOM (big-endian), the BOM is stripped and string
    #   is converted to UTF-8
    # - 0xFF 0xFE: UTF-16 with a BOM (little-endian), the BOM is stripped and string
    #   is converted to UTF-8
    # - 0x00 'B' or 0x00 'b': UTF-16 (big-endian), the string is converted to UTF-8
    # - 'B' 0x00 or 'b' 0x00: UTF-16 (little-endian), the string is converted to UTF-8
    #
    # If you know that you have only one vCard, then you can decode that
    # single vCard by doing something like:
    #
    #   vcard = Vcard.decode(card_data).first
    #
    # Note: Should the import encoding be remembered, so that it can be reencoded in
    # the same format?
    def Vcard.decode(card)
      if card.respond_to? :to_str
        string = card.to_str
      elsif card.kind_of? IO
        string = card.read(nil)
      else
        raise ArgumentError, "Vcard.decode cannot be called with a #{card.type}"
      end

      case string
        when /^\xEF\xBB\xBF/
          string = string.sub("\xEF\xBB\xBF", '')
        when /^\xFE\xFF/
          arr = string.unpack('n*')
          arr.shift
          string = arr.pack('U*')
        when /^\xFF\xFE/
          arr = string.unpack('v*')
          arr.shift
          string = arr.pack('U*')
        when /^\x00\x62/i
          string = string.unpack('n*').pack('U*')
        when /^\x62\x00/i
          string = string.unpack('v*').pack('U*')
      end

      entities = Vpim.expand(Vpim.decode(string))

      # Since all vCards must have a begin/end, the top-level should consist
      # entirely of entities/arrays, even if its a single vCard.
      if entities.detect { |e| ! e.kind_of? Array }
        raise "Not a valid vCard"
      end

      vcards = []

      for e in entities
        vcards.push(new(e.flatten, 'VCARD'))
      end

      vcards
    end

    # The value of the field named +name+, optionally limited to fields of
    # type +type+. If no match is found, nil is returned, if multiple matches
    # are found, the first match to have one of its type values be 'PREF'
    # (preferred) is returned, otherwise the first match is returned.
    #
    # FIXME - this will become an alias for #value.
    def [](name, type=nil)
      fields = enum_by_name(name).find_all { |f| type == nil || f.type?(type) }

      valued = fields.select { |f| f.value != '' }
      if valued.first
        fields = valued
      end

      # limit to preferred, if possible
      pref = fields.select { |f| f.pref? }

      if pref.first
        fields = pref
      end

      fields.first ? fields.first.value : nil
    end

    # Return the Line#value for a specific +name+, and optionally for a
    # specific +type+.
    #
    # If no line with the +name+ (and, optionally, +type+) exists, nil is
    # returned.
    #
    # If multiple lines exist, the order of preference is:
    # - lines with values over lines without
    # - lines with a type of 'pref' over lines without
    # If multiple lines are equally preferred, then the first line will be
    # returned.
    #
    # This is most useful when looking for a line that can not occur multiple
    # times, or when the line can occur multiple times, and you want to pick
    # the first preferred line of a specific type. See #values if you need to
    # access all the lines.
    #
    # Note that the +type+ field parameter is used for different purposes by
    # the various kinds of vCard lines, but for the addressing lines (ADR,
    # LABEL, TEL, EMAIL) it is has a reasonably consistent usage. Each
    # addressing line can occur multiple times, and a +type+ of 'pref'
    # indicates that a particular line is the preferred line. Other +type+
    # values tend to indicate some information about the location ('home',
    # 'work', ...) or some detail about the address ('cell', 'fax', 'voice',
    # ...). See the methods for the specific types of line for information
    # about supported types and their meaning.
    def value(name, type = nil)
      v = nil

      fields = enum_by_name(name).find_all { |f| type == nil || f.type?(type) }

      valued = fields.select { |f| f.value != '' }
      if valued.first
        fields = valued
      end

      pref = fields.select { |f| f.pref? }

      if pref.first
        fields = pref
      end

      if fields.first
         line = Line.decode(@@decode, self, fields.first)

         if line
           return line.value
         end
      end

      nil
    end

    # A variant of #lines that only iterates over specific Line names. Since
    # the name is known, only the Line#value is returned or yielded.
    def values(name)
      unless block_given?
        lines(name).map { |line| line.value }
      else
        lines(name) { |line| yield line.value }
      end
    end

    # The first ADR value of type +type+, a Address. Any of the location or
    # delivery attributes of Address can be used as +type+. A wrapper around
    # #value('ADR', +type+).
    def address(type=nil)
      value('ADR', type)
    end

    # The ADR values, an array of Address. If a block is given, the values are
    # yielded. A wrapper around #values('ADR').
    def addresses #:yield:address
      values('ADR')
    end

    # The AGENT values. Each AGENT value is either a String, a Uri, or a Vcard.
    # If a block is given, the values are yielded. A wrapper around
    # #values('AGENT').
    def agents #:yield:agent
      values('AGENT')
    end

    # The BDAY value as either a Date or a DateTime, or nil if there is none.
    #
    # If the BDAY value is invalidly formatted, a feeble heuristic is applied
    # to find the month and year, and return a Date in the current year.
    def birthday
      value('BDAY')
    end

    # The CATEGORIES values, an array of String. A wrapper around
    # #value('CATEGORIES').
    def categories
      value('CATEGORIES')
    end

    # The first EMAIL value of type +type+, a Email. Any of the location
    # attributes of Email can be used as +type+. A wrapper around
    # #value('EMAIL', +type+).
    def email(type=nil)
      value('EMAIL', type)
    end

    # The EMAIL values, an array of Email. If a block is given, the values are
    # yielded. A wrapper around #values('EMAIL').
    def emails #:yield:email
      values('EMAIL')
    end

    # The GEO value, an Array of two Floats, +[ latitude, longitude]+.  North
    # of the equator is positive latitude, east of the meridian is positive
    # longitude.  See RFC2445 for more info, there are lots of special cases
    # and RFC2445's description is more complete thant RFC2426.
    def geo
      value('GEO')
    end

    # Return an Array of KEY Line#value, or yield each Line#value if a block
    # is given. A wrapper around #values('KEY').
    #
    # KEY is a public key or authentication certificate associated with the
    # object that the vCard represents. It is not commonly used, but could
    # contain a X.509 or PGP certificate.
    #
    # See Attachment for a description of the value.
    def keys(&proc) #:yield: Line.value
      values('KEY', &proc)
    end

    # Return an Array of LOGO Line#value, or yield each Line#value if a block
    # is given. A wrapper around #values('LOGO').
    #
    # LOGO is a graphic image of a logo associated with the object the vCard
    # represents. Its not common, but would probably be equivalent to the logo
    # on printed card.
    #
    # See Attachment for a description of the value.
    def logos(&proc) #:yield: Line.value
      values('LOGO', &proc)
    end

    ## MAILER

    # The N and FN as a Name object.
    #
    # N is required for a vCards, this raises InvalidEncodingError if
    # there is no N so it cannot return nil.
    def name
      value('N') || raise(Vpim::InvalidEncodingError, "Missing mandatory N field")
    end

    # The first NICKNAME value, nil if there are none.
    def nickname
      v = value('NICKNAME')
      v = v.first if v
      v
    end

    # The NICKNAME values, an array of String. The array may be empty.
    def nicknames
      values('NICKNAME').flatten.uniq
    end

    # The NOTE value, a String. A wrapper around #value('NOTE').
    def note
      value('NOTE')
    end

    # The ORG value, an Array of String. The first string is the organization,
    # subsequent strings are departments within the organization. A wrapper
    # around #value('ORG').
    def org
      value('ORG')
    end

    # Return an Array of PHOTO Line#value, or yield each Line#value if a block
    # is given. A wrapper around #values('PHOTO').
    #
    # PHOTO is an image or photograph information that annotates some aspect of
    # the object the vCard represents. Commonly there is one PHOTO, and it is a
    # photo of the person identified by the vCard.
    #
    # See Attachment for a description of the value.
    def photos(&proc) #:yield: Line.value
      values('PHOTO', &proc)
    end

    ## PRODID

    ## PROFILE

    ## REV

    ## ROLE

    # Return an Array of SOUND Line#value, or yield each Line#value if a block
    # is given. A wrapper around #values('SOUND').
    #
    # SOUND is digital sound content information that annotates some aspect of
    # the vCard. By default this type is used to specify the proper
    # pronunciation of the name associated with the vCard. It is not commonly
    # used. Also, note that there is no mechanism available to specify that the
    # SOUND is being used for anything other than the default.
    #
    # See Attachment for a description of the value.
    def sounds(&proc) #:yield: Line.value
      values('SOUND', &proc)
    end

    ## SOURCE

    # The first TEL value of type +type+, a Telephone. Any of the location or
    # capability attributes of Telephone can be used as +type+. A wrapper around
    # #value('TEL', +type+).
    def telephone(type=nil)
      value('TEL', type)
    end

    # The TEL values, an array of Telephone. If a block is given, the values are
    # yielded. A wrapper around #values('TEL').
    def telephones #:yield:tel
      values('TEL')
    end

    ## TITLE

    ## UID

    # The URL value, a Uri. A wrapper around #value('NOTE').
    def url
      value('URL')
    end

    # The VERSION multiplied by 10 as an Integer.  For example, a VERSION:2.1
    # vCard would have a version of 21, and a VERSION:3.0 vCard would have a
    # version of 30.
    #
    # VERSION is required for a vCard, this raises InvalidEncodingError if
    # there is no VERSION so it cannot return nil.
    def version
      v = value('VERSION')
      unless v
        raise Vpim::InvalidEncodingError, 'Invalid vCard - it has no version field!'
      end
      v
    end

    # Make changes to a vCard.
    #
    # Yields a Vpim::Vcard::Maker that can be used to modify this vCard.
    def make #:yield: maker
      Vpim::Vcard::Maker.make2(self) do |maker|
        yield maker
      end
    end

    # Delete +line+ if block yields true.
    def delete_if #:nodoc: :yield: line
      # Do in two steps to not mess up progress through the enumerator.
      rm = []

      each do |f|
        line = f2l(f)
        if line && yield(line)
          rm << f

          # Hack - because we treat N and FN as one field
          if f.name? 'N'
            rm << field('FN')
          end
        end
      end

      rm.each do |f|
        @fields.delete( f )
        @cache.delete( f )
      end

    end

    # A class to make and make changes to vCards.
    #
    # It can be used to create completely new vCards using Vcard#make2.
    #
    # Its is also yielded from Vpim::Vcard#make, in which case it allows a kind
    # of transactional approach to changing vCards, so their values can be
    # validated after any changes have been made.
    #
    # Examples:
    # - link:ex_mkvcard.txt: example of creating a vCard
    # - link:ex_cpvcard.txt: example of copying and them modifying a vCard
    # - link:ex_mkv21vcard.txt: example of creating version 2.1 vCard
    # - link:ex_mkyourown.txt: example of adding support for new fields to Vcard::Maker
    class Maker
      # Make a vCard.
      #
      # Yields +maker+, a Vpim::Vcard::Maker which allows fields to be added to
      # +card+, and returns +card+, a Vpim::Vcard.
      #
      # If +card+ is nil or not provided a new Vpim::Vcard is created and the
      # fields are added to it.
      #
      # Defaults:
      # - vCards must have both an N and an FN field, #make2 will fail if there
      #   is no N field in the +card+ when your block is finished adding fields.
      # - If there is an N field, but no FN field, FN will be set from the
      #   information in N, see Vcard::Name#preformatted for more information.
      # - vCards must have a VERSION field. If one does not exist when your block is
      #   is finished it will be set to 3.0.
      def self.make2(card = Vpim::Vcard.create, &block) # :yields: maker
        new(nil, card).make(&block)
      end

      # Deprecated, use #make2.
      #
      # If set, the FN field will be set to +full_name+. Otherwise, FN will
      # be set from the values in #name.
      def self.make(full_name = nil, &block) # :yields: maker
        new(full_name, Vpim::Vcard.create).make(&block)
      end

      def make # :nodoc:
        yield self
        unless @card['N']
          raise Unencodeable, 'N field is mandatory'
        end
        fn = @card.field('FN')
        if fn && fn.value.strip.length == 0
          @card.delete(fn)
          fn = nil
        end
        unless fn
          @card << Vpim::DirectoryInfo::Field.create('FN', Vpim::Vcard::Name.new(@card['N'], '').formatted)
        end
        unless @card['VERSION']
          @card << Vpim::DirectoryInfo::Field.create('VERSION', "3.0")
        end
        @card
      end

      private

      def initialize(full_name, card) # :nodoc:
        @card = card || Vpim::Vcard::create
        if full_name
          @card << Vpim::DirectoryInfo::Field.create('FN', full_name.strip )
        end
      end

      public

      # Deprecated, see #name.
      #
      # Use
      #   maker.name do |n| n.fullname = "foo" end
      # to set just fullname, or set the other fields to set fullname and the
      # name.
      def fullname=(fullname) #:nodoc: bacwards compat
        if @card.field('FN')
          raise Vpim::InvalidEncodingError, "Not allowed to add more than one FN field to a vCard."
        end
        @card << Vpim::DirectoryInfo::Field.create( 'FN', fullname );
      end

      # Set the name fields, N and FN.
      #
      # Attributes of +name+ are:
      # - family: family name
      # - given: given name
      # - additional: additional names
      # - prefix: such as "Ms." or "Dr."
      # - suffix: such as "BFA", or "Sensei"
      #
      # +name+ is a Vcard::Name.
      #
      # All attributes are optional, though have all names be zero-length
      # strings isn't really in the spirit of  things. FN's value will be set
      # to Vcard::Name#formatted if Vcard::Name#fullname isn't given a specific
      # value.
      #
      # Warning: This is the only mandatory field.
      def name #:yield:name
        x = begin
              @card.name.dup
            rescue
              Vpim::Vcard::Name.new
            end

        fn = x.fullname

        yield x

        x.fullname.strip!

        delete_if do |line|
          line.name == 'N'
        end

        @card << x.encode
        @card << x.encode_fn

        self
      end

      alias :add_name :name #:nodoc: backwards compatibility

      # Add an address field, ADR. +address+ is a Vpim::Vcard::Address.
      def add_addr # :yield: address
        x = Vpim::Vcard::Address.new
        yield x
        @card << x.encode
        self
      end

      # Add a telephone field, TEL. +tel+ is a Vpim::Vcard::Telephone.
      #
      # The block is optional, its only necessary if you want to specify
      # the optional attributes.
      def add_tel(number) # :yield: tel
        x = Vpim::Vcard::Telephone.new(number)
        if block_given?
          yield x
        end
        @card << x.encode
        self
      end

      # Add an email field, EMAIL. +email+ is a Vpim::Vcard::Email.
      #
      # The block is optional, its only necessary if you want to specify
      # the optional attributes.
      def add_email(email) # :yield: email
        x = Vpim::Vcard::Email.new(email)
        if block_given?
          yield x
        end
        @card << x.encode
        self
      end

      # Set the nickname field, NICKNAME.
      #
      # It can be set to a single String or an Array of String.
      def nickname=(nickname)
        delete_if { |l| l.name == 'NICKNAME' }

        @card << Vpim::DirectoryInfo::Field.create( 'NICKNAME', nickname );
      end

      # Add a birthday field, BDAY.
      #
      # +birthday+ must be a time or date object.
      #
      # Warning: It may confuse both humans and software if you add multiple
      # birthdays.
      def birthday=(birthday)
        if !birthday.respond_to? :month
          raise ArgumentError, 'birthday must be a date or time object.'
        end
        delete_if { |l| l.name == 'BDAY' }
        @card << Vpim::DirectoryInfo::Field.create( 'BDAY', birthday );
      end

      # Add a note field, NOTE. The +note+ String can contain newlines, they
      # will be escaped.
      def add_note(note)
        @card << Vpim::DirectoryInfo::Field.create( 'NOTE', Vpim.encode_text(note) );
      end

      # Add an instant-messaging/point of presence address field, IMPP. The address
      # is a URL, with the syntax depending on the protocol.
      #
      # Attributes of IMPP are:
      # - preferred: true - set if this is the preferred address
      # - location: home, work, mobile - location of address
      # - purpose: personal,business - purpose of communications
      #
      # All attributes are optional, and so is the block.
      #
      # The URL syntaxes for the messaging schemes is fairly complicated, so I
      # don't try and build the URLs here, maybe in the future. This forces
      # the user to know the URL for their own address, hopefully not too much
      # of a burden.
      #
      # IMPP is defined in draft-jennings-impp-vcard-04.txt. It refers to the
      # URI scheme of a number of messaging protocols, but doesn't give
      # references to all of them:
      # - "xmpp" indicates to use XMPP, draft-saintandre-xmpp-uri-06.txt
      # - "irc" or "ircs" indicates to use IRC, draft-butcher-irc-url-04.txt
      # - "sip" indicates to use SIP/SIMPLE, RFC 3261
      # - "im" or "pres" indicates to use a CPIM or CPP gateway, RFC 3860 and RFC 3859
      # - "ymsgr" indicates to use yahoo
      # - "msn" might indicate to use Microsoft messenger
      # - "aim" indicates to use AOL
      #
      def add_impp(url) # :yield: impp
        params = {}

        if block_given?
          x = Struct.new( :location, :preferred, :purpose ).new

          yield x

          x[:preferred] = 'PREF' if x[:preferred]

          types = x.to_a.flatten.compact.map { |s| s.downcase }.uniq

          params['TYPE'] = types if types.first
        end

        @card << Vpim::DirectoryInfo::Field.create( 'IMPP', url, params)
        self
      end

      # Add an X-AIM account name where +xaim+ is an AIM screen name.
      #
      # I don't know if this is conventional, or supported by anything other
      # than AddressBook.app, but an example is:
      #   X-AIM;type=HOME;type=pref:exampleaccount
      #
      # Attributes of X-AIM are:
      # - preferred: true - set if this is the preferred address
      # - location: home, work, mobile - location of address
      #
      # All attributes are optional, and so is the block.
      def add_x_aim(xaim) # :yield: xaim
        params = {}

        if block_given?
          x = Struct.new( :location, :preferred ).new

          yield x

          x[:preferred] = 'PREF' if x[:preferred]

          types = x.to_a.flatten.compact.map { |s| s.downcase }.uniq

          params['TYPE'] = types if types.first
        end

        @card << Vpim::DirectoryInfo::Field.create( 'X-AIM', xaim, params)
        self
      end


      # Add a photo field, PHOTO.
      #
      # Attributes of PHOTO are:
      # - image: set to image data to include inline
      # - link: set to the URL of the image data
      # - type: string identifying the image type, supposed to be an "IANA registered image format",
      #     or a non-registered image format (usually these start with an x-)
      #
      # An error will be raised if neither image or link is set, or if both image
      # and link is set.
      #
      # Setting type is optional for a link image, because either the URL, the
      # image file extension, or a HTTP Content-Type may specify the type. If
      # it's not a link, setting type is mandatory, though it can be set to an
      # empty string, <code>''</code>, if the type is unknown.
      #
      # TODO - I'm not sure about this API. I'm thinking maybe it should be
      # #add_photo(image, type), and that I should detect when the image is a
      # URL, and make type mandatory if it wasn't a URL.
      def add_photo # :yield: photo
        x = Struct.new(:image, :link, :type).new
        yield x
        if x[:image] && x[:link]
          raise Vpim::InvalidEncodingError, 'Image is not allowed to be both inline and a link.'
        end

        value = x[:image] || x[:link]

        if !value
          raise Vpim::InvalidEncodingError, 'A image link or inline data must be provided.'
        end

        params = {}

        # Don't set type to the empty string.
        params['TYPE'] = x[:type] if( x[:type] && x[:type].length > 0 )

        if x[:link]
          params['VALUE'] = 'URI'
        else # it's inline, base-64 encode it
          params['ENCODING'] = :b64
          if !x[:type]
            raise Vpim::InvalidEncodingError, 'Inline image data must have it\'s type set.'
          end
        end

        @card << Vpim::DirectoryInfo::Field.create( 'PHOTO', value, params )
        self
      end

      # Add a URL field, URL.
      def add_url(url)
        @card << Vpim::DirectoryInfo::Field.create( 'URL', url.to_str );
      end

      # Add a Field, +field+.
      def add_field(field)
        fieldname = field.name.upcase
        case
        when [ 'BEGIN', 'END' ].include?(fieldname)
          raise Vpim::InvalidEncodingError, "Not allowed to manually add #{field.name} to a vCard."

        when [ 'VERSION', 'N', 'FN' ].include?(fieldname)
          if @card.field(fieldname)
            raise Vpim::InvalidEncodingError, "Not allowed to add more than one #{fieldname} to a vCard."
          end
          @card << field

        else
          @card << field
        end
      end

      # Copy the fields from +card+ into self using #add_field. If a block is
      # provided, each Field from +card+ is yielded. The block should return a
      # Field to add, or nil.  The Field doesn't have to be the one yielded,
      # allowing the field to be copied and modified (see Field#copy) before adding, or 
      # not added at all if the block yields nil.
      #
      # The vCard fields BEGIN and END aren't copied, and VERSION, N, and FN are copied
      # only if the card doesn't have them already.
      def copy(card) # :yields: Field
        card.each do |field|
          fieldname = field.name.upcase
          case
          when [ 'BEGIN', 'END' ].include?(fieldname)
            # Never copy these

          when [ 'VERSION', 'N', 'FN' ].include?(fieldname) && @card.field(fieldname)
            # Copy these only if they don't already exist.

          else
            if block_given?
              field = yield field
            end

            if field
              add_field(field)
            end
          end
        end
      end

      # Delete +line+ if block yields true.
      def delete_if #:yield: line
        begin
        @card.delete_if do |line|
          yield line
        end
        rescue NoMethodError
          # FIXME - this is a hideous hack, allowing a DirectoryInfo to
          # be passed instead of a Vcard, and for it to almost work. Yuck.
        end
      end

    end
  end
end

