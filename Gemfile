source :rubygems

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
adapter = 'pg' if adapter == 'postgresql'
gem adapter

# Run-time dependencies
gem 'rails', '3.0.10'
gem 'columnize', '0.3.4'
gem 'rdoc', '3.8', :require => nil
gem 'geokit', '1.5.0'
gem 'htmlentities', '4.2.3'
gem 'paper_trail', '2.2.4'
gem 'ri_cal', '0.8.8'
gem 'rubyzip', '0.9.4', :require =>  'zip/zip'
gem 'will_paginate', '3.0.pre2'
gem 'httparty', '0.8.1'
gem 'multi_json' # Use whichever version 'httparty' wants, needed for our specs
gem 'loofah', '1.0.0'
gem 'loofah-activerecord', '1.0.0'
gem 'bluecloth', '2.1.0'
gem 'formtastic', '2.0.0.rc3'
gem 'validation_reflection', '1.0.0'
gem 'acts-as-taggable-on', '2.0.6'
gem 'themes_for_rails', '0.4.2'
gem 'jquery-rails', '1.0.12'

# gem 'paper_trail_manager', :git => 'https://github.com/igal/paper_trail_manager.git'
# gem 'paper_trail_manager', :path => '../paper_trail_manager'
gem 'paper_trail_manager'

gem 'exception_notification', '2.4.1'

# Some dependencies are only needed for test and development environments. On
# production servers, you can skip their installation by running:
#   bundle install --without development:test
group :development, :test do
  gem 'rspec-rails', '2.11.0'
  gem 'webrat', '0.7.3'
  gem 'rcov', '0.9.9', :require => false
  gem 'factory_girl_rails', '1.0.1'

  gem 'ruby-debug', :platform => :mri_18
  gem 'ruby-debug19', :platform => :mri_19
end

# Some dependencies are activated through server settings.
require "#{basedir}/lib/secrets_reader"
secrets = SecretsReader.read(:silent => true)
case secrets.search_engine
when 'sunspot'
  sunspot_version = '1.3.0.rc4'
  gem 'sunspot_rails', sunspot_version
  gem 'sunspot_solr',  sunspot_version
end
