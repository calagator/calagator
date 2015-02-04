require File.expand_path('../boot', __FILE__)

require 'rails/all'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

require "formtastic"
require "rails_autolink"
require "nokogiri"
require "columnize"
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
require "progress_bar"
require "exception_notification"
require "font-awesome-rails"
require "paper_trail_manager"
require "utf8-cleaner"
require "rack/robustness"
require_relative "../vendor/gems/mofo-0.2.8/lib/mofo"
require "sunspot_rails"
require "sunspot_solr"
require "lucene_query"

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

    # Settings specified here will take precedence over those in config/application.rb

    # The test environment is used exclusively to run your application's
    # test suite.  You never need to work with it otherwise.  Remember that
    # your test database is "scratch space" for the test suite and is wiped
    # and recreated between test runs.  Don't rely on the data there!
    config.cache_classes = true

    # Configure static asset server for tests with Cache-Control for performance
    config.serve_static_assets = true
    config.static_cache_control = "public, max-age=3600"

    # Log error messages when you accidentally call methods on nil.
    config.whiny_nils = true

    # Show full error reports and disable caching
    config.consider_all_requests_local       = true
    config.action_controller.perform_caching = false

    # Raise exceptions instead of rendering exception templates
    config.action_dispatch.show_exceptions = false

    # Disable request forgery protection in test environment
    config.action_controller.allow_forgery_protection    = false

    # Tell Action Mailer not to deliver emails to the real world.
    # The :test delivery method accumulates sent emails in the
    # ActionMailer::Base.deliveries array.
    config.action_mailer.delivery_method = :test

    # Use SQL instead of Active Record's schema dumper when creating the test database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql

    # Print deprecation notices to the stderr
    config.active_support.deprecation = :stderr

    # initializers
    config.secret_token = '9d6410100d898ea314f2a36977ae6db32508767871244e74064dfba9c027d37916e4106383c1f419c778ab1335de6978498659db37f14f2cbe6dc2478caf4f65'

    # routes

    config.before_initialize do
      Calagator.draw_routes self
    end
  end
end
