# frozen_string_literal: true

module Calagator
  class Engine < ::Rails::Engine
    isolate_namespace Calagator

    middleware.use 'Rack::JSONP'

    config.assets.precompile += %w[
      *.png
      *.gif
      calagator/errors.css
      leaflet.js
      leaflet_google_layer.js
      site-icon.png
      spinner.gif
      tag_icons/*
      leaflet
    ]

    config.after_initialize do
      Calagator.configure_search_engine
    end
  end
end
