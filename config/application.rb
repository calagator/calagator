require File.expand_path('../boot', __FILE__)

require 'rails/all'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module Calagator
  class Application < Rails::Application
    #---[ Path -------------------------------------------------------------

    config.autoload_paths += %W(
      #{config.root}/app/mixins
      #{config.root}/app/observers
      #{config.root}/lib
    )

    #---[ Rails ]-----------------------------------------------------------

    # Activate observers that should always be running
    # config.active_record.observers = :cacher, :garbage_collector
    config.active_record.observers = :cache_observer

    # Deliver email using sendmail by default
    config.action_mailer.delivery_method = :sendmail
    config.action_mailer.sendmail_settings = { :arguments => '-i' }

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    config.i18n.enforce_available_locales = true

    #---[ Caching ]---------------------------------------------------------

    require 'fileutils'
    cache_path = Rails.root.join('tmp','cache',Rails.env)
    config.cache_store = :file_store, cache_path
    FileUtils.mkdir_p(cache_path)

    #---[ Asset Pipeline ]--------------------------------------------------
    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    config.assets.precompile += [
      "leaflet.js",
      "leaflet_google_layer.js",
      "errors.css"
    ]

    #---[ Rack Middleware ]-------------------------------------------------

    config.middleware.use Rack::Robustness do |g|
      g.no_catch_all
      g.on(ArgumentError) { |ex| 400 }
      g.content_type 'text/plain'
      g.body{ |ex| ex.message.to_s.encode('UTF-8', {:invalid => :replace, :undef => :replace, :replace => '?'}) }
      g.ensure(true) { |ex| env['rack.errors'].write(ex.message.to_s.encode('UTF-8', {:invalid => :replace, :undef => :replace, :replace => '?'})) }
    end

    #---[ Secrets and settings ]--------------------------------------------

    config.before_initialize do
      # Read secrets
      require 'secrets_reader'
      ::SECRETS = SecretsReader.read

      # Read theme
      require 'theme_reader'
      ::THEME_NAME = ThemeReader.read

      # Read theme settings
      require 'settings_reader'
      ::SETTINGS = SettingsReader.read(Rails.root.join('themes',THEME_NAME,'settings.yml'))

      # Set timezone for Rails
      config.time_zone = SETTINGS.timezone || 'Pacific Time (US & Canada)'
    end

    # Set timezone for OS
    config.after_initialize do
      ENV['TZ'] = Time.zone.tzinfo.identifier
    end
  end
end
