class SourceParser
  # == SourceParser::Hcal
  #
  # Reads hCalendar events.
  class Hcal < Base
    label :hCalendar

    # Returns a set of hCalendar events.
    #
    # Options:
    # * :url => URL String to read events from.
    def self.to_hcals(opts={})
      something = hCalendar.find(:text => read_url(opts[:url]))
      return(something.is_a?(hCalendar) ? [something] : something)
    end
  end
end
