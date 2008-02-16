require 'mofo'
require 'open-uri'
require 'set'

# == SourceParser
#
# A hierarchy of classes that provide a way to parse different source formats and return hCalendar events.
class SourceParser
  # Return Array of hCalendar objects by reading them from the +format_type+ parser and passing it a set of +opts+. 
  # Please see the parsers that subclass Base for arguments.
  #
  # Example:
  #
  #   hcal_entries = SourceParser.to_hcals(:hcal, :url => "http://my.hcal/feed/")
  def self.to_hcals(format_type, opts)
    parser_for(format_type).to_hcals(opts)
  end

  def self.to_abstract_events(format_type, opts)
    parser_for(format_type).to_abstract_events(opts)
  end

  # Return a format-specific parser for +format_type+
  def self.parser_for(format_type)
    const_get(format_type.to_s.humanize)
  end

  # Returns a Hash of format types to human-readable labels
  def self.formats_to_labels
    # TODO How to dynamically generate a list of parsers? The trouble is that Rails reloading throws away class variables, 
    # so simply populating an array when a class inherits from another will only work for the first request, but will be 
    # cleared afterwards.
    result = {}
    for parser in [Hcal]
      result[parser.to_s.split('::').last.to_sym] = parser.label
    end
    return result
  end

  # Returns an Array of strings for all the known format types
  def self.known_format_types
    constants.reject{|t| t == "Base"}
  end

  # == SourceParser::Base
  #
  # The base class for all format-specific parsers. Do not use this class
  # directly, use a subclass of Base to do the parsing instead.
  class Base
    # Gets or sets the human-readable label for this parser
    def self.label(value=nil)
      @@label = value.to_sym if value
      @@label
    end

    # Returns content read from a URL. Easier to stub.
    def self.read_url(url)
      open(url){|h| h.read}
    end

    # Stub which makes sure that subclasses of Base implement the #parse method.
    def self.to_hcals(opts={})
      raise NotImplementedError, "Do not use #{self.class}.to_hcals method directly"
    end

    # Stub which makes sure that subclasses of Base implement the #parse method.
    def self.to_abstract_events(opts={})
      raise NotImplementedError, "Do not use #{self.class}.to_abstract_events method directly"
    end
  end
  
  
  AbstractEvent = Struct.new(:title, :description, :start_time, :url, :location) do
  end
  
end

# Load all the format-specific drivers in the "source_parser" directory
source_parser_driver_path = File.join(File.dirname(__FILE__), "source_parser")
for entry in Dir.entries(source_parser_driver_path).select{|t| t.match(/.+\.rb$/)}
  require File.join(source_parser_driver_path, entry)
end
