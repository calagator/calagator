$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "calagator/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "calagator"
  s.version     = Calagator::VERSION
  s.authors     = ["The Calagator Team"]
  s.email       = ["calagator-development@googlegroups.com"]
  s.homepage    = "https://github.com/calagator/calagator"
  s.summary     = "A calendar for communities"
  s.description = "Calagator is an open source community calendaring platform"
  s.license     = "MIT"

  s.required_ruby_version = ['>= 2.0.0', '< 2.2.0']

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE.txt", "Rakefile", "README.md"]
  s.test_files = Dir["spec/**/*"]

  # When changing this Rails requirement, also update RAILS_REQUIREMENT in rails_template.rb
  s.add_dependency "rails", "~> 4.0"

  s.add_dependency "rails-observers"
  s.add_dependency "sass-rails"
  s.add_dependency "sass", "~> 3.2"
  s.add_dependency "formtastic", "~> 3.1"
  s.add_dependency "rails_autolink", "~> 1.1"
  s.add_dependency "nokogiri"
  s.add_dependency "geokit", "~> 1.9.0"
  s.add_dependency "htmlentities", "~> 4.3"
  s.add_dependency "ri_cal", "~> 0.8.8"
  s.add_dependency "will_paginate", "~> 3.0"
  s.add_dependency "rest-client", "~> 1.8"
  s.add_dependency "loofah", "~> 2.0"
  s.add_dependency "loofah-activerecord", "~> 1.2"
  s.add_dependency "bluecloth", "~> 2.2"
  s.add_dependency "acts-as-taggable-on", "~> 3.5"
  s.add_dependency "jquery-rails"
  s.add_dependency "jquery-ui-rails", "~> 5.0"
  s.add_dependency "font-awesome-rails", "~> 4.3"
  s.add_dependency "paper_trail_manager", "~> 0.3.0"
  s.add_dependency "utf8-cleaner", "~> 0.0.6"
  # s.add_dependency "mofo", path: "vendor/gems/mofo-0.2.8" # vendored fork with hpricot dependency replaced with nokogiri
  s.add_dependency "sunspot_rails", "~> 2.1"
  s.add_dependency "sunspot_solr",  "~> 2.1"
  s.add_dependency "lucene_query", "0.1"

  s.add_development_dependency "sqlite3", "~> 1.3"
  s.add_development_dependency "rspec-activemodel-mocks", "~> 1.0"
  s.add_development_dependency "rspec-its", "~> 1.1"
  s.add_development_dependency "rspec-rails", "~> 3.2"
  s.add_development_dependency "rspec-collection_matchers", "~> 1.1"
  s.add_development_dependency "factory_girl_rails", "~> 4.5"
  s.add_development_dependency "faker", "~> 1.4"
  s.add_development_dependency "capybara", "~> 2.4"
  s.add_development_dependency "coveralls", "~> 0.8.1"
  s.add_development_dependency "database_cleaner", "~> 1.4"
  s.add_development_dependency "poltergeist", "~> 1.6"
  s.add_development_dependency "timecop", "~> 0.7.1"
  s.add_development_dependency "webmock", "~> 1.20"
  s.add_development_dependency "simplecov", "~> 0.10.0"
  s.add_development_dependency "appraisal", "~> 2.0"
  s.add_development_dependency "gem-release", "~> 0.7"
end
