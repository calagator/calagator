#===[ Gemfile usage ]===================================================
#
# This Gemfile activates the following gems in an unusual way:
#
# * The database gem is retrieved from the `config/database.yml` file.
# * The debugger and code coverage are only activated if a `.dev` file exists.
# * The Sunspot indexer is only activated if enabled in the secrets file.
# * Additional gems may be loaded from a `Gemfile.local` file if it exists.

#=======================================================================

source :rubygems

unless defined?($BUNDLER_INTERPRETER_CHECKED)
  if defined?(JRUBY_VERSION)
    puts "WARNING: JRuby cannot run Calagator. Its version of Nokogiri is incompatible with 'loofah', 'mofo' and other things. Although basic things like running the console and starting the server work, you'll run into problems as soon as you try to add/edit records or import hCalendar events."
    $JRUBY_WARNED = true
  elsif defined?(RUBY_ENGINE) && RUBY_ENGINE == 'rbx'
    puts "WARNING: Rubinius cannot run Calagator. It's multibyte string handling is broken in ways that break 'loofah' and other libraries. You won't even be able to start the console because this is such a severe problem."
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

# Load additional gems from "Gemfile.local" if it exists, has same format as this file.
begin
  data = File.read("#{basedir}/Gemfile.local")
rescue Errno::ENOENT
  # Ignore
end
eval data if data

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
  # The latest "mysql2" gem isn't compatible with our Rails 3.0
  gem adapter, '~> 0.2.0'
when 'jdbcsqlite3'
  gem 'jdbc-sqlite3'
  gem 'activerecord-jdbcsqlite3-adapter'
else
  gem adapter
end

# Run-time dependencies
gem 'rails', '3.0.14'
gem 'columnize', '0.3.6'
gem 'rdoc', '3.12', :require => false
gem 'geokit', '1.6.5'
gem 'htmlentities', '4.3.1'
gem 'paper_trail', '2.6.3'
gem 'ri_cal', '0.8.8'
gem 'rubyzip', '0.9.9', :require =>  'zip/zip'
gem 'will_paginate', '3.0.3'
gem 'httparty', '0.8.3'
gem 'multi_json' # Use whichever version 'httparty' wants, needed for our specs
gem 'loofah', '1.2.1'
gem 'loofah-activerecord', '1.0.0'
gem 'bluecloth', '2.2.0'
gem 'formtastic', '2.0.2' # 2.1 and above change the syntax significantly :(
gem 'validation_reflection', '1.0.0'
gem 'acts-as-taggable-on', '2.3.3'
gem 'themes_for_rails', '0.5.1'
gem 'jquery-rails', '1.0.19'
gem 'progress_bar', '0.4.0'
gem 'exception_notification', '2.6.1'

# gem 'paper_trail_manager', :git => 'https://github.com/igal/paper_trail_manager.git'
# gem 'paper_trail_manager', :path => '../paper_trail_manager'
gem 'paper_trail_manager', '0.1.4'

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
  gem 'capistrano', '2.12.0'
  gem 'capistrano-ext', '1.2.1'

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

    platform :mri_19 do
      gem 'debugger'
      gem 'debugger-ruby_core_source'
      gem 'simplecov'
    end

    platform :jruby do
      gem 'ruby-debug'
    end
  end
end

# Some dependencies are activated through server settings.
require "#{basedir}/lib/secrets_reader"
secrets = SecretsReader.read(:silent => true)
case secrets.search_engine
when 'sunspot'
  sunspot_version = '1.3.3'
  gem 'sunspot_rails', sunspot_version
  gem 'sunspot_solr',  sunspot_version
end
