# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "calagator/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name = "calagator"
  s.version = Calagator::VERSION
  s.authors = ["the Calagator team"]
  s.email = ["info@calagator.org"]
  s.homepage = "https://github.com/calagator/calagator"
  s.summary = "A calendar for communities"
  s.description = "Calagator is an open source community calendaring platform"
  s.license = "MIT"

  s.required_ruby_version = [">= 2.6.0"]

  s.files = Dir["{app,config,lib,vendor}/**/*"] + Dir["db/**/*.rb"] + ["MIT-LICENSE.txt", "Rakefile", "README.md", "rails_template.rb"]
  s.executables << "calagator"

  # To change this Rails requirement, update RAILS_VERSION in lib/calagator/version.rb
  s.add_dependency "rails", Calagator::RAILS_VERSION
  s.add_dependency "sprockets-rails", "~> 3.4"
  s.add_dependency "activemodel-serializers-xml", "~> 1.0"
  s.add_dependency "acts-as-taggable-on", "~> 10.0"
  s.add_dependency "annotate", ">= 3.1.1", "< 3.3.0"
  s.add_dependency "bluecloth", "~> 2.2"
  s.add_dependency "bootsnap", "~> 1.16"
  s.add_dependency "font-awesome-rails", "~> 4.7"
  s.add_dependency "formtastic", "~> 5.0"
  s.add_dependency "geokit", ">= 1.9", "< 1.14"
  s.add_dependency "htmlentities", "~> 4.3"
  s.add_dependency "jquery-rails", "~> 4.4"
  s.add_dependency "jquery-ui-rails", "~> 6.0"
  s.add_dependency "loofah", "~> 2.0"
  s.add_dependency "loofah-activerecord", ">= 1.2", "< 3.0"
  s.add_dependency "lucene_query", "0.1"
  s.add_dependency "microformats", "~> 4.5"
  s.add_dependency "nokogiri", "~> 1.14"
  s.add_dependency "paper_trail", "~> 15.1"
  s.add_dependency "rack-contrib", "~> 2.3"
  s.add_dependency "rails-observers", "~> 0.1.5"
  s.add_dependency "rails_autolink", "~> 1.1"
  s.add_dependency "recaptcha", "~> 5.8"
  s.add_dependency "rest-client", "~> 2.0"
  s.add_dependency "demingfactor-ri_cal", "~> 0.10.0"
  s.add_dependency "sassc-rails", "~> 2.1"
  s.add_dependency "standard", "~> 1.28.0"
  s.add_dependency "sunspot_rails", "~> 2.1"
  s.add_dependency "utf8-cleaner", ">= 0.0.6", "< 1.1.0"
  s.add_dependency "validate_url", "~> 1.0.15"
  s.add_dependency "will_paginate", "~> 3.0"
  s.add_dependency "pg", "~> 0.19.0"
  s.add_dependency "sqlite3", "~> 1.5.4"
  # Fix deprecation warning with Zeitwerk
  s.add_dependency "observer", "~> 0.1"
  # s.add_dependency "listen", "~> 3.1.5"

  s.add_development_dependency "appraisal", "~> 2.4"
  s.add_development_dependency "capybara", "~> 3.31"
  s.add_development_dependency "database_cleaner", "~> 2.0"
  s.add_development_dependency "factory_bot_rails", "~> 5.2"
  s.add_development_dependency "faker", "~> 2.2"
  s.add_development_dependency "gem-release", "~> 2.0"
  s.add_development_dependency "puma", "~> 6.0.0"
  s.add_development_dependency "rspec-activemodel-mocks", "~> 1.1.0"
  s.add_development_dependency "rspec-collection_matchers", "~> 1.1"
  s.add_development_dependency "rspec-its", "~> 1.1"
  s.add_development_dependency "rspec-rails", "~> 6.1"
  s.add_development_dependency "selenium-webdriver", "~> 4.18"
  s.add_development_dependency "simplecov", "~> 0.18"
  s.add_development_dependency "simplecov-lcov", "~> 0.8"
  s.add_development_dependency "sunspot_solr", "~> 2.1"
  s.add_development_dependency "timecop", "~> 0.9.5"
  s.add_development_dependency "uglifier", "~> 4.2.0"
  s.add_development_dependency "webmock", "~> 3.5"
end
