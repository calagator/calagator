require File.expand_path('../boot', __FILE__)

require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module Calagator
  class Application < Rails::Application
    #---[ Libraries ]-------------------------------------------------------

    # Gems are packaged in "Gemfile", run `bundle` to install them.

    # Standard libraries
    require 'fileutils'

    # Bundled libraries
    $LOAD_PATH << Rails.root.join('vendor','gems','lucene_query-0.1','lib')
    require 'lucene_query'

    $LOAD_PATH << Rails.root.join('vendor','gems','mofo-0.2.8','lib')
    require 'mofo'

    # "/lib" libraries
    $LOAD_PATH << Rails.root.join

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

    #---[ Plugins ]---------------------------------------------------------

    # Load these plugins first, or they won't work
    config.plugins = [
      :catch_cookie_exception,
      :exception_notification,
    ]

    # Load remaining plugins
    for entry in Pathname.glob(Rails.root + 'vendor/plugins/*')
      name = entry.basename.to_s
      symbol = name.to_sym
      next if ['.', '..'].include?(name)
      next if config.plugins.include?(symbol)
      next unless entry.directory?
      config.plugins << symbol
    end

    #---[ Path -------------------------------------------------------------

    config.autoload_paths += [
      Rails.root.join('app','mixins'),
      Rails.root.join('app','observers')
    ]

    config.eager_load_paths += [
      Rails.root.join('lib')
    ]

    #---[ Caching ]---------------------------------------------------------

    cache_path = Rails.root.join('tmp','cache',Rails.env)
    config.cache_store = :file_store, cache_path
    FileUtils.mkdir_p(cache_path)

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
      require 'lib/search_engine'
      SearchEngine.kind = SECRETS.search_engine

      case SearchEngine.kind
      when :acts_as_solr
        config.plugins << :acts_as_solr
      end
    end

    # Set timezone for OS
    config.after_initialize do
      ENV['TZ'] = Time.zone.tzinfo.identifier
    end
  end
end
