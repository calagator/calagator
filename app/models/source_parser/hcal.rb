require 'htmlentities'

class SourceParser
  HTMLEntitiesCoder = HTMLEntities.new
  
  # == SourceParser::Hcal
  #
  # Reads hCalendar events.
  class Hcal < SourceParser::Base
    label :hCalendar

    # Returns a set of hCalendar events.
    #
    # Options:
    # * :url => URL String to read events from.
    def self.to_hcals(opts={})
      something = hCalendar.find(:text => read_url(opts[:url]))
      return(something.is_a?(hCalendar) ? [something] : something)
    end
    
    # Returns a set of AbstractEvent objects.
    #
    # Options:
    # * :url => URL String to read events from.
    def self.to_abstract_events(opts = {})
      field_map = {
        :title => :summary,
        :description => :description,
        :start_time => :dtstart,
        :url => :url,
      }
      hcals = to_hcals(opts)
      hcals.map do |hcal|
        returning(AbstractEvent.new) do |event|
          field_map.each do |event_field, mofo_field|
            next unless hcal.respond_to?(mofo_field)
            raw_field = hcal.send(mofo_field)
            decoded_field = (mofo_field == :dtstart) ? 
              HTMLEntitiesCoder.decode(raw_field) : 
              raw_field
            event.send("#{event_field}=", decoded_field)
          end
        end
      end
    end
  end
end
