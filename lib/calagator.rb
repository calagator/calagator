require "calagator/engine"

require "formtastic"
require "rails_autolink"
require "rails-observers"
require "nokogiri"
require "geokit"
require "htmlentities"
require "paper_trail"
require "ri_cal"
require "will_paginate"
require "will_paginate/array"
require "rest-client"
require "loofah"
require "loofah-activerecord"
require "bluecloth"
require "formtastic"
require "acts-as-taggable-on"
require "jquery-rails"
require "jquery-ui-rails"
require "font-awesome-rails"
require "paper_trail_manager"
require "utf8-cleaner"
require "sunspot_rails"
require "sunspot_solr"
require "lucene_query"

module Calagator
  mattr_accessor :title,
    :tagline,
    :url,
    :administrator_email,
    :admin_username,
    :admin_password,
    :meetup_api_key,
    :search_engine,
    :icalendar_sequence_offset,
    :mapping_marker_color,
    :mapping_google_maps_api_key,
    :mapping_provider,
    :mapping_tiles,
    :venues_map_options,
    :blacklist_patterns

  self.title = 'Calagator'
  self.tagline = 'A Tech Calendar'
  self.url = 'http://my-calagator.org/'
  self.administrator_email = 'your@email.addr'
  self.search_engine = :sql
  self.icalendar_sequence_offset = 0
  self.mapping_marker_color = 'green'
  self.mapping_provider = 'stamen'
  self.mapping_tiles = 'terrain'
  self.venues_map_options = {}
  self.blacklist_patterns = [
    /\b(online|overseas).+(drugstore|pharmacy)\b/,
    /\bcialis\b/,
  ]

  def self.configure_search_engine
    kind = search_engine.try(:to_sym)

    Calagator::Event::SearchEngine.use(kind)
    Calagator::Venue::SearchEngine.use(kind)
  end

  def self.setup(&block)
    yield self
  end
end
