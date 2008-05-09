# == SourceParser
#
# A hierarchy of classes that provide a way to parse different source formats and return hCalendar events.
class SourceParser
  # Return an Array of AbstractEvent instances.
  #
  # Options: (these vary between specific parsers)
  # * :url - URL string to read as parser input.
  # * :content - String to read as parser input.
  def self.to_abstract_events(opts)
    events = []

    # TODO where does content_for belong?
    content = Base.content_for(opts)
    content = CGI::unescapeHTML(content) if content.respond_to?(:content_type) and content.content_type == "application/atom+xml"
    
    for parser in parsers
      begin
        events += parser.to_abstract_events(opts.merge(:content => content))
      rescue Exception => e
        # FIXME We really shouldn't be just throwing out all of these exceptions.
        # Ignore
      end
    end

    return events
  end

  # Returns a Hash of format types to human-readable labels
  def self.formats_to_labels
    result = ::ActiveSupport::OrderedHash.new
    for parser in $SourceParserImplementations.sort_by{|t| t.label.to_s}
      result[parser.to_s.demodulize.to_sym] = parser.label
    end
    return result
  end

  # Returns an Array of parser classes for the various formats
  def self.parsers
    $SourceParserImplementations.map{|parser| parser}.uniq
  end

  # == SourceParser::Base
  #
  # The base class for all format-specific parsers. Do not use this class
  # directly, use a subclass of Base to do the parsing instead.
  class Base
    def self.inherited(subclass)
      # Add class-wide ::_label accessor to subclasses.
      subclass.meta_eval {attr_accessor :_label}

      # Use global because it's the only data structure that survives a Rails #reload!
      $SourceParserImplementations ||= Set.new
      $SourceParserImplementations << subclass
    end

    # Gets or sets the human-readable label for this parser.
    def self.label(value=nil)
      self._label = value if value
      return _label
    end

    # Returns content from either the :content option or by reading a :url.
    def self.content_for(opts)
      opts[:content] || read_url(opts[:url])
    end

    # Returns content read from a URL. Easier to stub.
    def self.read_url(url)
      URI.parse(url).read
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
end

# Load all the format-specific drivers in the "source_parser" directory
source_parser_driver_path = File.join(File.dirname(__FILE__), "source_parser")
for entry in Dir.entries(source_parser_driver_path).select{|t| t.match(/.+\.rb$/)}
  require File.join(source_parser_driver_path, entry)
end
