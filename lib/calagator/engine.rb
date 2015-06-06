module Calagator
  class Engine < ::Rails::Engine
    isolate_namespace Calagator

    config.assets.precompile += %w( 
      markers-soft.png
      markers-shadow.png
      markers-soft@2x.png
      markers-shadow@2x.png
      leaflet.js
      leaflet_google_layer.js
      mustache.js
      leaflet
    )
  end
end
