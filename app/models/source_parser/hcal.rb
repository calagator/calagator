class SourceParser
  class Hcal < Base
    def self.parse(opts={})
      _parse_wrapper(opts) do
        returning([]) do |events|
          for result in [hCalendar.find(:text => read_url(opts[:source].url))].flatten
            events << Event.new(:title => result.summary, :description => result.description, :start_time => result.dtstart, :url => result.url)
          end
        end
      end
    end
  end
end
