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
    mattr_accessor :title, :tagline, :url, :venues_map_options, :blacklist_patterns

    self.title = 'Calagator'
    self.tagline = 'A Tech Calendar'
    self.url = 'http://my-calagator.org/'
    self.venues_map_options = {}
    self.blacklist_patterns = [
      /\b(online|overseas).+(drugstore|pharmacy)\b/,
      /\bcialis\b/,
    ]

    # map the attrs from initializer
    def setup(&block)
      yield self
    end
  end
end
