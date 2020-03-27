# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'calagator/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'calagator'
  s.version     = Calagator::VERSION
  s.authors     = ['the Calagator team']
  s.email       = ['info@calagator.org']
  s.homepage    = 'https://github.com/calagator/calagator'
  s.summary     = 'A calendar for communities'
  s.description = 'Calagator is an open source community calendaring platform'
  s.license     = 'MIT'

  s.required_ruby_version = ['>= 2.5.0']

  s.files = Dir['{app,config,lib,vendor}/**/*'] + Dir['db/**/*.rb'] + ['MIT-LICENSE.txt', 'Rakefile', 'README.md', 'rails_template.rb']
  s.test_files = Dir['spec/**/*']
  s.executables << 'calagator'

  # When changing this Rails requirement, also update RAILS_REQUIREMENT in rails_template.rb
  s.add_dependency 'rails', '~> 4.2'

  s.add_dependency 'acts-as-taggable-on', '~> 3.5'
  s.add_dependency 'bluecloth', '~> 2.2'
  s.add_dependency 'font-awesome-rails', '~> 4.3'
  s.add_dependency 'formtastic', '~> 3.1'
  s.add_dependency 'geokit', '>= 1.9', '< 1.14'
  s.add_dependency 'htmlentities', '~> 4.3'
  s.add_dependency 'jquery-rails'
  s.add_dependency 'jquery-ui-rails', '~> 5.0'
  s.add_dependency 'loofah', '~> 2.0'
  s.add_dependency 'loofah-activerecord', '>= 1.2', '< 3.0'
  s.add_dependency 'lucene_query', '0.1'
  s.add_dependency 'microformats', '>= 4.0.7', '< 4.3.0'
  s.add_dependency 'nokogiri'
  s.add_dependency 'paper_trail_manager', '~> 0.5.0'
  s.add_dependency 'rack-contrib', '>= 1', '< 3'
  s.add_dependency 'rails-observers'
  s.add_dependency 'rails_autolink', '~> 1.1'
  s.add_dependency 'recaptcha', '>= 5.3', '< 5.5'
  s.add_dependency 'rest-client', '~> 2.0'
  s.add_dependency 'ri_cal', '~> 0.8.8'
  s.add_dependency 'sassc-rails', '>= 1.3', '< 3.0'
  s.add_dependency 'sunspot_rails', '~> 2.1'
  s.add_dependency 'utf8-cleaner', '>= 0.0.6', '< 1.1.0'
  s.add_dependency 'validate_url', '~> 1.0'
  s.add_dependency 'will_paginate', '~> 3.0'

  s.add_development_dependency 'appraisal', '~> 2.0'
  s.add_development_dependency 'capybara', '~> 3.31'
  s.add_development_dependency 'database_cleaner', '~> 1.4'
  s.add_development_dependency 'factory_bot_rails', '~> 4.11.1'
  s.add_development_dependency 'faker', '~> 2.2'
  s.add_development_dependency 'gem-release', '~> 2.0'
  s.add_development_dependency 'puma', '~> 4.3.0'
  s.add_development_dependency 'rspec-activemodel-mocks', '~> 1.1.0'
  s.add_development_dependency 'rspec-collection_matchers', '~> 1.1'
  s.add_development_dependency 'rspec-its', '~> 1.1'
  s.add_development_dependency 'rspec-rails', '~> 3.2'
  s.add_development_dependency 'rubocop', '~> 0.80.0'
  s.add_development_dependency 'rubocop-performance', '~> 1.5.0'
  s.add_development_dependency 'rubocop-rails', '~> 2.4.0'
  s.add_development_dependency 'rubocop-rspec', '~> 1.38.0'
  s.add_development_dependency 'selenium-webdriver'
  s.add_development_dependency 'simplecov', '~> 0.18'
  s.add_development_dependency 'simplecov-lcov', '~> 0.8'
  s.add_development_dependency 'sqlite3', '~> 1.3.6'
  s.add_development_dependency 'sunspot_solr', '~> 2.1'
  s.add_development_dependency 'timecop', '~> 0.7.1'
  s.add_development_dependency 'uglifier', '>= 1.3.0'
  s.add_development_dependency 'webdrivers'
  s.add_development_dependency 'webmock', '~> 3.5'
end
