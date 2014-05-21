#===[ Gemfile usage ]===================================================
#
# This Gemfile activates the following gems in an unusual way:
#
# * The database gem is retrieved from the `config/database.yml` file.
# * The debugger and code coverage are only activated if a `.dev` file exists.
# * The Sunspot indexer is only activated if enabled in the secrets file.
# * Additional gems may be loaded from a `Gemfile.local` file if it exists.

#=======================================================================

source 'https://rubygems.org'

unless defined?($BUNDLER_INTERPRETER_CHECKED)
  if defined?(JRUBY_VERSION)
    puts "WARNING: JRuby cannot run Calagator. Its version of Nokogiri is incompatible with 'loofah', 'mofo' and other things. Although basic things like running the console and starting the server work, you'll run into problems as soon as you try to add/edit records or import hCalendar events."
    $JRUBY_WARNED = true
  end
  $BUNDLER_INTERPRETER_CHECKED = true
end

basedir = File.dirname(__FILE__)

# Use "syck" YAML engine on Ruby 1.9.2 with early versions (e.g. p180) because
# the default "psyche" engine is broken -- it doesn't support merge keys,
# produce output it can't parse, etc.
if defined?(Syck::Syck) and defined?(YAML::ENGINE)
  YAML::ENGINE.yamler = 'syck'
end

# Database driver
require 'erb'
require 'yaml'
filename = File.join(File.dirname(__FILE__), 'config', 'database.yml')
raise "Can't find database configuration at: #{filename}" unless File.exist?(filename)
databases = YAML.load(ERB.new(File.read(filename)).result)
railsenv = ENV['RAILS_ENV'] || 'development'
raise "Can't find database configuration for environment '#{railsenv}' in: #{filename}" unless databases[railsenv]
adapter = databases[railsenv]['adapter']
raise "Can't find database adapter for environment '#{railsenv}' in: #{filename}" unless databases[railsenv]['adapter']
case adapter
when 'pg', 'postgresql'
  gem 'pg'
when 'mysql2'
  gem 'mysql2', '~> 0.3.11'
when 'jdbcsqlite3'
  gem 'jdbc-sqlite3'
  gem 'activerecord-jdbcsqlite3-adapter'
else
  gem adapter
end

gem 'puma', '2.6.0'

# Run-time dependencies
gem 'rails', '3.2.17'
gem 'rails_autolink', '1.1.3'
gem 'nokogiri', '1.5.11'
gem 'columnize', '0.3.6'
gem 'rdoc', '3.12.2', :require => false
gem 'geokit', '1.6.5'
gem 'htmlentities', '4.3.1'
gem 'paper_trail', '2.7.2'
gem 'ri_cal', '0.8.8'
gem 'rubyzip', '0.9.9', :require =>  'zip/zip'
gem 'will_paginate', '3.0.5'
gem 'httparty', '0.11.0'
gem 'multi_json' # Use whichever version 'httparty' wants, needed for our specs
gem 'loofah', '1.2.1'
# NOTE: 'loofah-activerecord' doesn't support Rails 3.2, so use my fork:
gem 'loofah-activerecord', :git => 'git://github.com/igal/loofah-activerecord.git', :branch => 'with_rails_3.1_and_3.2'
gem 'bluecloth', '2.2.0'
gem 'formtastic', '2.2.1'
# validation_reflection 1.0.0 doesn't support Rails 3.2, so use unofficial patches:
#gem 'validation_reflection', :git => 'git://github.com/ncri/validation_reflection.git', :ref => '60320e6beb088808fd625a8d958dbd0d2661d494'
gem 'acts-as-taggable-on', '2.4.1'
gem 'jquery-rails', '1.0.19'
gem 'progress_bar', '1.0.0'
gem 'exception_notification', '2.6.1'
gem 'font-awesome-rails', '3.2.1.3'

# gem 'paper_trail_manager', :git => 'https://github.com/igal/paper_trail_manager.git'
# gem 'paper_trail_manager', :path => '../paper_trail_manager'
gem 'paper_trail_manager', '>= 0.2.0'

gem 'utf8-cleaner', '~> 0.0.6'

platform :jruby do
  gem 'activerecord-jdbc-adapter'
  gem 'jruby-openssl'
  gem 'jruby-rack'
  gem 'warbler'

  gem 'activerecord-jdbcsqlite3-adapter'
  gem 'jdbc-sqlite3'
end

# Some dependencies are only needed for test and development environments. On
# production servers, you can skip their installation by running:
#   bundle install --without development:test
group :development, :test do
  gem 'rspec-rails', '2.11.0'
  gem 'webrat', '0.7.3'
  gem 'factory_girl_rails', '1.7.0' # 2.0 and above don't support Ruby 1.8.7 :(
  gem 'spork', '~> 0.9.2'
  gem 'database_cleaner', '~> 0.8.0'

  # Do not install these interactive libraries onto the continuous integration server.
  unless ENV['CI'] || ENV['TRAVIS']
    # Deployment
    gem 'capistrano', '3.0.1'
    gem 'capistrano-rails', '1.0.0'
    gem 'capistrano-bundler', '1.0.0'

    # Guard and plugins
    platforms :ruby_19, :ruby_20 do
      gem 'guard', '~> 1.3.0'
      gem 'guard-rspec', '~> 1.2.1'
      gem 'guard-spork', '~> 1.1.0'
    end

    # Guard notifier
    case RUBY_PLATFORM
    when /-*darwin.*/ then gem 'growl'
    when /-*linux.*/ then gem 'libnotify'
    end
  end

  # Optional libraries add debugging and code coverage functionality, but are not
  # needed otherwise. These are not activated by default because they may cause
  # Ruby or RVM to hang, complicate installation, and upset travis-ci. To
  # activate them, create a `.dev` file and rerun Bundler, e.g.:
  #
  #   touch .dev && bundle
  if File.exist?(File.join(File.dirname(File.expand_path(__FILE__)), ".dev"))
    platform :mri_18 do
      gem 'ruby-debug'
      gem 'rcov'
    end

    platforms :mri_19, :mri_20 do
      gem 'debugger'
      gem 'debugger-ruby_core_source'
      gem 'simplecov'
    end

    platform :jruby do
      gem 'ruby-debug'
    end
  end
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'sass', '~> 3.2.14'
  # gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyracer', :platforms => :ruby

  # Minify assets.  Requires a javascript runtime, such as 'therubyracer'
  # above. You will also need to set 'config.assets.compress' to true in
  # config/environments/production.rb
  gem 'uglifier', '>= 1.0.3'
end

# Some dependencies are activated through server settings.
require "#{basedir}/lib/secrets_reader"
secrets = SecretsReader.read(:silent => true)
case secrets.search_engine
when 'sunspot'
  sunspot_version = '2.1.0'
  gem 'sunspot_rails', sunspot_version
  gem 'sunspot_solr',  sunspot_version
end

# Load additional gems from "Gemfile.local" if it exists, has same format as this file.
begin
  data = File.read("#{basedir}/Gemfile.local")
rescue Errno::ENOENT
  # Ignore
end
eval data if data
