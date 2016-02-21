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

# Database driver
gem 'pg'
gem 'sqlite3'

gem 'puma', '2.6.0'

# Run-time dependencies
gem 'rails', '3.2.19'
gem 'rails_autolink', '1.1.3'
gem 'nokogiri', '1.5.11'
gem 'columnize', '0.3.6'
gem 'rdoc', '3.12.2', :require => false
gem 'geokit', '1.6.5'
gem 'htmlentities', '4.3.1'
gem 'paper_trail', '2.7.2'
gem 'ri_cal', '0.8.8'
gem 'rubyzip'
gem 'will_paginate', '3.0.5', require: ['will_paginate', 'will_paginate/array']
gem 'rest-client', '1.6.7'
gem 'loofah', '1.2.1'
gem 'loofah-activerecord', '1.1.0'
gem 'bluecloth', '2.2.0'
gem 'formtastic', '2.2.1'
gem 'acts-as-taggable-on', '2.4.1'
gem 'jquery-rails', '~> 3.0.0'
gem 'progress_bar', '1.0.0'
gem 'exception_notification', '2.6.1'
gem 'font-awesome-rails', '3.2.1.3'
gem 'paper_trail_manager', '>= 0.2.0'
gem 'utf8-cleaner', '~> 0.0.6'
gem 'rack-robustness', '~> 1.1.0'
gem 'mofo', path: 'vendor/gems/mofo-0.2.8' # vendored fork with hpricot dependency replaced with nokogiri
gem 'sunspot_rails', '2.1.1'
gem 'sunspot_solr',  '2.1.1'
gem 'lucene_query', '0.1'
gem 'carrierwave', '~> 0.10.0'
gem 'rmagick'
gem 'recurring_select', github: "VolunteerOdyssey/recurring_select", branch: "vo"

# Some dependencies are only needed for test and development environments. On
# production servers, you can skip their installation by running:
#   bundle install --without development:test
group :development, :test do
  gem 'rspec-activemodel-mocks'
  gem 'rspec-its'
  gem 'rspec-rails', '~> 3'
  gem 'rspec-collection_matchers'
  gem 'spring', '1.1.3'
  gem 'spring-commands-rspec', '1.0.2'
  gem 'factory_girl_rails'
  gem 'faker', '1.4.3'

  # Do not install these interactive libraries onto the continuous integration server.
  unless ENV['CI'] || ENV['TRAVIS']
    # Deployment
    gem 'capistrano', '3.0.1'
    gem 'capistrano-rails', '1.0.0'
    gem 'capistrano-bundler', '1.0.0'

    # Guard and plugins
    platforms :mri do
      gem 'guard', '~> 1.3.0'
      gem 'guard-rspec', '~> 1.2.1'
    end
  end

  # Optional libraries add debugging and code coverage functionality, but are not
  # needed otherwise. These are not activated by default because they may cause
  # Ruby or RVM to hang, complicate installation, and upset travis-ci. To
  # activate them, create a `.dev` file and rerun Bundler, e.g.:
  #
  #   touch .dev && bundle
  if File.exist?(".dev")
    platforms :mri do
      gem 'byebug'
      gem 'simplecov'
    end
  end
end

group :development do
  gem 'better_errors', '1.1.0'
  gem 'binding_of_caller', '0.7.2'

  gem 'pry-rails', '~> 0.3.3'
  gem 'quiet_assets', '~> 1.1.0'
end

group :test do
  gem 'capybara', '2.4.3'
  gem 'capybara-screenshot'
  gem 'coveralls', '0.7.0', require: false
  gem 'database_cleaner'
  gem 'poltergeist', '1.5.1'
  gem 'timecop', '~> 0.7'
  gem 'webmock', '~> 1.20'
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'sass', '~> 3.2.14'
  # gem 'coffee-rails', '~> 3.2.1'
  gem 'jquery-ui-rails'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyracer', :platforms => :ruby

  # Minify assets.  Requires a javascript runtime, such as 'therubyracer'
  # above. You will also need to set 'config.assets.compress' to true in
  # config/environments/production.rb
  gem 'uglifier', '>= 1.0.3'
end

# Load additional gems from "Gemfile.local" if it exists
eval_gemfile "Gemfile.local" if File.exist?("Gemfile.local")
