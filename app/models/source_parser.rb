require 'mofo'
require 'open-uri'

# == SourceParser
#
# A hierarchy of classes that provide a way to parse different source formats and return hCalendar events.
class SourceParser
  # Return Array of hCalendar objects by reading them from the +format_type+ parser and passing it a set of +opts+. Please see the parsers that subclass Base for arguments.
  #
  # Example:
  #
  #   hcal_entries = SourceParser.parse(:hcal, :url => "http://my.hcal/feed/")
  def self.parse(format_type, opts)
    parser_for(format_type).parse(opts)
  end

  # Return a format-specitic parser for +format_type+
  def self.parser_for(format_type)
    const_get(format_type.to_s.humanize)
  end

  # == SourceParser::Base
  #
  # The base class for all format-specific parsers. Do not use this class
  # directly, use a subclass of Base to do the parsing instead.
  class Base
    # Returns content read from a URL. Easier to stub.
    def self.read_url(url)
      open(url){|h| h.read}
    end

    # Stub which makes sure that subclasses of Base implement the #parse method.
    def self.parse(opts={})
      raise NotImplementedError, "Do not use #{self.class}.parse method directly"
    end
  end
end

# Load all the format-specific drivers in the "source_parser" directory
source_parser_driver_path = File.join(File.dirname(__FILE__), "source_parser")
for entry in Dir.entries(source_parser_driver_path).select{|t| t.match(/.+\.rb$/)}
  require File.join(source_parser_driver_path, entry)
end
