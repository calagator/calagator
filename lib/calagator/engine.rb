# frozen_string_literal: true
require 'rack/contrib/jsonp'

module Calagator
  class Engine < ::Rails::Engine
    isolate_namespace Calagator

    config.middleware.use Rack::JSONP

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

    if config.active_record.respond_to?(:yaml_column_permitted_classes)
      config.active_record.yaml_column_permitted_classes = [Symbol, Date, Time]
    end

    config.after_initialize do
      Calagator.configure_search_engine
    end
  end
end
