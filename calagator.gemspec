$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "calagator/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "calagator"
  s.version     = Calagator::VERSION
  s.authors     = ["TODO: Your name"]
  s.email       = ["TODO: Your email"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of Calagator."
  s.description = "TODO: Description of Calagator."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["LICENSE.txt", "Rakefile", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", "~> 3.2.19"
  s.add_dependency "sass-rails", "~> 3.2.3"
  s.add_dependency "sass", ">= 3.2.14"
  s.add_dependency "formtastic", "2.2.1"
  s.add_dependency "rails_autolink", "1.1.3"
  s.add_dependency "nokogiri", "1.5.11"
  s.add_dependency "columnize", "0.3.6"
  s.add_dependency "geokit", "1.6.5"
  s.add_dependency "htmlentities", "4.3.1"
  s.add_dependency "paper_trail", "2.7.2"
  s.add_dependency "ri_cal", "0.8.8"
  s.add_dependency "rubyzip"
  s.add_dependency "will_paginate", "3.0.5" #, require: ["will_paginate", "will_paginate/array"]
  s.add_dependency "rest-client", "1.6.7"
  s.add_dependency "loofah", "1.2.1"
  s.add_dependency "loofah-activerecord", "1.1.0"
  s.add_dependency "bluecloth", "2.2.0"
  s.add_dependency "formtastic", "2.2.1"
  s.add_dependency "acts-as-taggable-on", "2.4.1"
  s.add_dependency "jquery-rails", ">= 1.0.19"
  s.add_dependency "progress_bar", "1.0.0"
  s.add_dependency "font-awesome-rails", "3.2.1.3"
  s.add_dependency "paper_trail_manager", ">= 0.2.0"
  s.add_dependency "utf8-cleaner", "~> 0.0.6"
  # s.add_dependency "mofo", path: "vendor/gems/mofo-0.2.8" # vendored fork with hpricot dependency replaced with nokogiri
  s.add_dependency "sunspot_rails", "2.1.1"
  s.add_dependency "sunspot_solr",  "2.1.1"
  s.add_dependency "lucene_query", "0.1"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-activemodel-mocks"
  s.add_development_dependency "rspec-its"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "rspec-collection_matchers"
  s.add_development_dependency "factory_girl_rails"
  s.add_development_dependency "faker"
  s.add_development_dependency "capybara"
  s.add_development_dependency "coveralls"
  s.add_development_dependency "database_cleaner"
  s.add_development_dependency "poltergeist"
  s.add_development_dependency "timecop"
  s.add_development_dependency "webmock"
  s.add_development_dependency "byebug"
  s.add_development_dependency "simplecov"
end
