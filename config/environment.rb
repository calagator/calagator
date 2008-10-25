# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '>= 2.1.0' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|

  config.gem "htmlentities"
  config.gem "vpim"
  config.gem "lucene_query"
  config.gem "rubyzip", :lib =>  "zip/zip"
  config.gem "has_many_polymorphs"
  config.gem "hpricot"

  config.time_zone = "Pacific Time (US & Canada)"

  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use (only works if using vendor/rails).
  # To use Rails without a database, you must remove the Active Record framework
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Only load the plugins named here, in the order given. By default, all plugins
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random,
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :session_key => '_calagator_session',
    :secret      => '7da1bbbbda1fbe53f8e845ccb07a0cff6951f9bad8b2cd9a3f80321ac842ffd801a746fecf8fcc2cf495041553be02c39e7cdc6c0a0d9710db19fd7d73a03802'
  }

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with 'rake db:sessions:create')
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector
  config.active_record.observers = :janitor_observer

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc

  config.load_paths += %W[
    #{RAILS_ROOT}/app/mixins
  ]

  cache_path = "#{RAILS_ROOT}/tmp/cache/#{RAILS_ENV}"
  config.cache_store = :file_store, cache_path
  FileUtils.mkdir_p(cache_path)
end

# NOTE: See config/initializers/ directory for additional code loaded at start-up
