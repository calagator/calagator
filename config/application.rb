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
    #---[ Libraries ]-------------------------------------------------------

    # Gems are packaged in "Gemfile", run `bundle` to install them.

    # Standard libraries
    require 'fileutils'
    require 'net/http'
    require 'net/https'
    require 'open-uri'
    require 'set'
    require 'uri'

    # Load from "/lib"
    $LOAD_PATH << Rails.root.join('lib')
    ### libraries
    require 'metaclass'
    require 'tag_model_extensions'
    ### monkeypatches
    require 'ext/nil_strip_html'
    require 'ext/object_logit'
    require 'ext/time_today'
    require 'ext/time_get_zone'

    # Adds Array#paginate
    require 'will_paginate/array'

    #---[ Plugins ]---------------------------------------------------------

    # Load these plugins first, or they won't work
    config.plugins = [
      :catch_cookie_exception,
      :exception_notification,
    ]

    #---[ Path -------------------------------------------------------------

    config.autoload_paths += %W(
      #{config.root}/app/mixins
      #{config.root}/app/observers
      #{config.root}/lib/catch_cookie_exception/lib
      #{config.root}/lib/exception_notification/lib
      #{config.root}/lib/has_many_polymorphs/lib
      #{config.root}/lib/gmaps_on_rails/lib
      #{config.root}/lib
    )

    #---[ Rails ]-----------------------------------------------------------

    # Activate observers that should always be running
    # config.active_record.observers = :cacher, :garbage_collector
    config.active_record.observers = :cache_observer

    # Deliver email using sendmail by default
    config.action_mailer.delivery_method = :sendmail
    config.action_mailer.sendmail_settings = { :arguments => '-i' }

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    config.i18n.enforce_available_locales = true

    #---[ Caching ]---------------------------------------------------------

    cache_path = Rails.root.join('tmp','cache',Rails.env)
    config.cache_store = :file_store, cache_path
    FileUtils.mkdir_p(cache_path)

    #---[ Asset Pipeline ]--------------------------------------------------
    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    config.assets.precompile += ["leaflet_google_layer.js"]

    #---[ Secrets and settings ]--------------------------------------------

    config.before_initialize do
      # Read secrets
      require 'secrets_reader'
      ::SECRETS = SecretsReader.read

      # Read theme
      require 'theme_reader'
      ::THEME_NAME = ThemeReader.read
      Kernel.class_eval do
        def theme_file(filename)
          return Rails.root.join('themes',THEME_NAME,filename)
        end
      end

      # Read theme settings
      require 'settings_reader'
      ::SETTINGS = SettingsReader.read(
        theme_file("settings.yml"), {
          'timezone' => 'Pacific Time (US & Canada)',
        }
      )

      # Set timezone for Rails
      config.time_zone = SETTINGS.timezone


      # Set cookie session
      config.session_store :cookie_store, :key => SECRETS.session_name || "calagator"
      config.secret_token = SECRETS.session_secret


      # Activate search engine
      require 'search_engine'
      SearchEngine.kind = Rails.env.test? ? "sql" : SECRETS.search_engine
    end

    # Set timezone for OS
    config.after_initialize do
      ENV['TZ'] = Time.zone.tzinfo.identifier
    end
  end
end
