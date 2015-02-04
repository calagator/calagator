require "routes"

module Calagator
  class Engine < ::Rails::Engine
    isolate_namespace Calagator

    initializer "routes" do |app|
      Calagator.draw_routes app
    end
  end
end
