class SourceParser # :nodoc:
  # == SourceParser::Upcoming
  #
  # Reads Upcoming events using their API.
  class Upcoming < Base
    label :Upcoming

    # Return the Upcoming event_id string extracted from an Upcoming Event URL.
    def self._upcoming_url_to_event_id(url)
      url.present? ?
        url[%r{http://(?:m\.)?upcoming.yahoo.com/event/(\d+)}, 1] :
        nil
    end

    # Return an Array of AbstractEvent instances extracted from input.
    #
    # Options:
    # * :url -- URL of iCalendar data to import
    # * :content -- String of iCalendar data to import
    # * :skip_old -- Should old events be skipped? Default is true.
    def self.to_abstract_events(opts={})
      event_id = self._upcoming_url_to_event_id(opts[:url])

      # If we don't already have an Upcoming API response, setup `opts` so #content_for will fetch it.
      if opts[:content].nil? or opts[:content] !~ /<rsp stat="ok" version="1.0"/m
        return false unless event_id # Give up unless we can extract the Upcoming event_id.

        api_key = SECRETS.upcoming_api_key
        api_url = "http://upcoming.yahooapis.com/services/rest/?api_key=#{api_key}&method=event.getInfo&event_id=#{event_id}"

        # Dup and alter `opts` for call to #content_for, without polluting it for other drivers.
        opts = opts.dup 
        opts[:url] = api_url
        opts[:content] = nil
      end

      content = content_for(opts)
      begin
        data = Hash.from_xml(content)
        leaf = data['rsp']['event']
      rescue Exception => e
        return false
      end

      event = AbstractEvent.new
      event.start_time  = Time.parse(leaf['utc_start'])
      event.title       = leaf['name']
      event.description = leaf['description']
      event.end_time    = Time.parse(leaf['utc_end'])
      event.url         = leaf['url']
      event.tags        = ["upcoming:event=#{event_id}"]

      location = AbstractLocation.new
      location.title          = leaf['venue_name']
      location.street_address = leaf['venue_address']
      location.locality       = leaf['venue_city']
      location.region         = leaf['venue_state_name']
      location.postal_code    = leaf['venue_zip']
      location.country        = leaf['venue_country_name']
      location.latitude       = leaf['latitude']
      location.longitude      = leaf['longitude']
      event.location          = location

      return [event]
    end
  end
end
