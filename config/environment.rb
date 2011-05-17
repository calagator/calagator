# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.10' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use. To use Rails without a database
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Specify gems that this application depends on. 
  # They can then be installed with "rake gems:install" on new installations.
  config.gem 'htmlentities', :version => '4.2.3'
  config.gem 'vpim', :version => '0.695'
  config.gem 'lucene_query' # bundled
  config.gem 'paper_trail', :version => '1.6.4'
  config.gem 'will_paginate', :version => '2.3.15'
  config.gem 'columnize', :version => '0.3.2'
  config.gem 'linecache', :version => '0.43'
  config.gem 'hpricot', :version => '0.8.3'
  config.gem 'rubyzip', :lib =>  'zip/zip', :version => '0.9.4'
  config.gem 'ri_cal', :version => '0.8.7'
  config.gem 'annotate-models', :version => '1.0.4', :lib => false
  # NOTE: mofo 0.2.9 and above are evil, defining their own defective Object#try method and are unable to extract "postal-code" address fields from hCalendar. Mofo is used in Calagator's SourceParser::Hcal and throughout for String#strip_html. The library has been abandoned and its author recommends switching to the incompatible "prism" gem.
  config.gem 'mofo', :version => '0.2.8'
  config.gem 'geokit', :version => '1.5.0'
  config.gem 'sanitize', :version => '2.0.1'

  case RAILS_ENV
  when "test", "development"
    config.gem 'rspec', :version => '1.3.1', :lib => false
    config.gem 'rspec-rails', :version => '1.3.3', :lib => false
  end

  require 'fileutils'

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

  # Make Time.zone default to the specified zone, and make Active Record store time values
  # in the database in UTC, and return them converted to the specified local zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Comment line to use default local time.
  ### config.time_zone = 'UTC'

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with "rake db:sessions:create")
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector
  config.active_record.observers = :cache_observer

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc
  # FIXME Figure out why ActiveRecord hasn't been told to use UTC timezone by default.

  # Deliver email using sendmail by default
  config.action_mailer.delivery_method = :sendmail

  #---[ Plugins ]---------------------------------------------------------

  config.plugins = [
    :catch_cookie_exception,
    :exception_notification,
    :gmaps_on_rails,
    :has_many_polymorphs,
    :jrails,
    :theme_support,
    :white_list,
  ]

  #---[ Path -------------------------------------------------------------

  config.autoload_paths += %W[
    #{RAILS_ROOT}/app/mixins
    #{RAILS_ROOT}/app/observers
  ]

  config.eager_load_paths += %W[
    #{RAILS_ROOT}/lib
  ]

  #---[ Caching ]---------------------------------------------------------

  cache_path = "#{RAILS_ROOT}/tmp/cache/#{RAILS_ENV}"
  config.cache_store = :file_store, cache_path
  FileUtils.mkdir_p(cache_path)
  
  #---[ Secrets and settings ]--------------------------------------------

  # Read secrets
  require 'secrets_reader'
  SECRETS = SecretsReader.read

  # Read theme
  require 'theme_reader'
  THEME_NAME = ThemeReader.read
  Kernel.class_eval do
    def theme_file(filename)
      return "#{RAILS_ROOT}/themes/#{THEME_NAME}/#{filename}"
    end
  end

  # Read settings
  require 'settings_reader'
  SETTINGS = SettingsReader.read(
    theme_file("settings.yml"), {
      'timezone' => 'Pacific Time (US & Canada)',
    }
  )

  # Set timezone for Rails
  config.time_zone = SETTINGS.timezone

  # Set timezone for OS
  ENV['TZ'] = SETTINGS.tz if SETTINGS.tz

  # Set cookie session
  config.action_controller.session = {
    :key => SECRETS.session_name || "calagator",
    :secret => SECRETS.session_secret,
  }

  # Activate search engine
  require 'lib/search_engine'
  SearchEngine.kind = SECRETS.search_engine
  case SearchEngine.kind
  when :acts_as_solr
    config.plugins << :acts_as_solr
  when :sunspot
    # The +require+ calls below are needed to make Sunspot available to Rake.
    # The +rescue+ calls below are needed so that `rake gems:install` can
    # install Sunspot.
    config.gem 'sunspot', :lib => 'sunspot', :version => '1.2.1'
    begin
      require 'sunspot'
    rescue LoadError => e
      # Ignore
    end
    config.gem 'sunspot_rails', :lib => 'sunspot/rails', :version => '1.2.1'
    begin
      require 'sunspot/rails'
    rescue LoadError => e
      # Ignore
    end
  end
end

# NOTE: See config/initializers/ directory for additional code loaded at start-up
