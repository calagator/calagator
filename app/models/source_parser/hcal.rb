class SourceParser
  # == SourceParser::Hcal
  #
  # Reads hCalendar events.
  class Hcal < Base
    # Returns a set of hCalendar events.
    #
    # Options:
    # * :url => URL String to read events from.
    def self.parse(opts={})
      return [hCalendar.find(:text => read_url(opts[:url]))].flatten
    end
  end
end
