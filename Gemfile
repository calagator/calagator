
basedir = File.dirname(__FILE__)

source 'https://rubygems.org'

# Use "syck" YAML engine on Ruby 1.9.2 with early versions (e.g. p180) because
# the default "psyche" engine is broken -- it doesn't support merge keys,
# produce output it can't parse, etc.
if defined?(Syck::Syck) and defined?(YAML::ENGINE)
  YAML::ENGINE.yamler = 'syck'
end

gem 'pg'

# Run-time dependencies
gem 'rails', '3.2.13'
gem 'rails_autolink', '1.0.9'
gem 'nokogiri', '1.5.10'
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
# NOTE: 'loofah-activerecord' doesn't support Rails 3.2, so use my fork:
gem 'loofah-activerecord', :git => 'git://github.com/igal/loofah-activerecord.git', :branch => 'with_rails_3.1_and_3.2'
gem 'bluecloth', '2.2.0'
gem 'formtastic', '2.0.2' # 2.1 and above change the syntax significantly :(
# validation_reflection 1.0.0 doesn't support Rails 3.2, so use unofficial patches:
gem 'validation_reflection', :git => 'git://github.com/ncri/validation_reflection.git', :ref => '60320e6beb088808fd625a8d958dbd0d2661d494'
gem 'acts-as-taggable-on', '2.3.3'
gem 'themes_for_rails', '0.5.1'
gem 'jquery-rails', '1.0.19'
gem 'progress_bar', '0.4.0'
gem 'exception_notification', '2.6.1'

# gem 'paper_trail_manager', :git => 'https://github.com/igal/paper_trail_manager.git'
# gem 'paper_trail_manager', :path => '../paper_trail_manager'
gem 'paper_trail_manager', '>= 0.2.0'

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
  gem 'sqlite3'
  gem 'rspec-rails', '2.11.0'
  gem 'webrat', '0.7.3'
  gem 'factory_girl_rails', '1.7.0' # 2.0 and above don't support Ruby 1.8.7 :(
  gem 'spork', '~> 0.9.2'
  gem 'database_cleaner', '~> 0.8.0'
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
