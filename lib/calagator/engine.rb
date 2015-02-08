module Calagator
  class Engine < ::Rails::Engine
    isolate_namespace Calagator

    config.before_initialize do
      # Read secrets
      require 'secrets_reader'
      ::SECRETS = SecretsReader.read
    end
  end

  # settings with defaults
  class << self
    mattr_accessor :title, :tagline, :url, :timezone, :precompile_assets, :venues_map_zoom, :venues_map_center
    self.title = 'Calagator'
    self.tagline = 'A Tech Calendar'
    self.url = 'http://calagator.org/'
    self.timezone = 'Pacific Time (US & Canada)'
  end

  # map the attrs from initializer
  def self.setup(&block)
    yield self
  end
end
