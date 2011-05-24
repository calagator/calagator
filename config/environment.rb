# Be sure to restart your server when you modify this file

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  #---[ Libraries ]-------------------------------------------------------

  # Gems are packaged in "Gemfile", run `bundle` to install them.

  # Standard libraries
  require 'fileutils'

  # Bundled libraries
  $LOAD_PATH << "#{RAILS_ROOT}/vendor/gems/lucene_query-0.1/lib"
  require 'lucene_query'

  #---[ Rails ]-----------------------------------------------------------

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector
  config.active_record.observers = :cache_observer

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

  # Read theme settings
  require 'settings_reader'
  SETTINGS = SettingsReader.read(
    theme_file("settings.yml"), {
      'timezone' => 'Pacific Time (US & Canada)',
    }
  )

  # Set timezone for Rails
  config.time_zone = SETTINGS.timezone

  # Set timezone for OS
  config.after_initialize do
    ENV['TZ'] = Time.zone.tzinfo.identifier
  end

  # Set cookie session
  config.action_controller.session = {
    :key => SECRETS.session_name || "calagator",
    :secret => SECRETS.session_secret,
  }

  # Activate search engine
  config.after_initialize do
    require 'lib/search_engine'
    SearchEngine.kind = SECRETS.search_engine

    case SearchEngine.kind
    when :acts_as_solr
      config.plugins << :acts_as_solr
    end
  end
end

# See "config/initializers/" directory for additional code loaded at start-up
