module Calagator
  class Engine < ::Rails::Engine
    isolate_namespace Calagator
  end

  # settings with defaults
  class << self
    mattr_accessor(:title) { 'Calagator' }
    mattr_accessor(:tagline) { 'A Tech Calendar' }
    mattr_accessor(:url) { 'http://my-calagator.org/' }
    mattr_accessor(:administrator_email) { 'your@email.addr' }
    mattr_accessor(:admin_username)
    mattr_accessor(:admin_password)
    mattr_accessor(:meetup_api_key)
    mattr_accessor(:search_engine) { :sql }
    mattr_accessor(:icalendar_sequence_offset) { 0 }
    mattr_accessor(:mapping_marker_color) { 'green' }
    mattr_accessor(:mapping_google_maps_api_key)
    mattr_accessor(:mapping_provider) { 'stamen' }
    mattr_accessor(:mapping_tiles) { 'terrain' }
    mattr_accessor(:venues_map_options) { {} }
    mattr_accessor(:blacklist_patterns) { [
      /\b(online|overseas).+(drugstore|pharmacy)\b/,
      /\bcialis\b/,
    ] }

    # map the attrs from initializer
    def setup(&block)
      yield self
    end
  end
end
