require 'mofo'
require 'open-uri'

class SourceParser
  def self.parse(format_type, opts)
    ::SourceParser.const_get(format_type.humanize).parse(opts)
  end

  class Base
    # Execute a parser's #parse method.
    #
    # Options:
    # * :preview -- Don't save the Event objects returned by #parse. Defaults to false.
    def self._parse_wrapper(opts={}, &block)
      events = block.call
      unless opts[:preview]
        for event in events
          event.save!
        end
      end
      events
    end

    # Returns content for a URL. Easier to stub.
    def self.read_url(url)
      open(url){|h| h.read}
    end
  end
end

# Load all the format-specific drivers in the source_parser's directory
source_parser_driver_path = File.join(File.dirname(__FILE__), "source_parser")
for entry in Dir.entries(source_parser_driver_path).select{|t| t.match(/.+\.rb$/)}
  require File.join(source_parser_driver_path, entry)
end
