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

# Database driver
require "./lib/database_yml_reader"
adapter = DatabaseYmlReader.read.adapter
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
gem 'httparty', '0.11.0'
gem 'loofah', '1.2.1'
gem 'loofah-activerecord', '1.1.0'
gem 'bluecloth', '2.2.0'
gem 'formtastic', '2.2.1'
gem 'acts-as-taggable-on', '2.4.1'
gem 'jquery-rails', '1.0.19'
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
  gem 'better_errors', '1.1.0'
  gem 'binding_of_caller', '0.7.2'
  gem 'rspec-activemodel-mocks'
  gem 'rspec-its'
  gem 'rspec-rails', '~> 3'
  gem 'capybara', '2.4.3'
  gem 'factory_girl_rails'
  gem 'timecop', '~> 0.7'
  gem 'spring', '1.1.3'
  gem 'spring-commands-rspec', '1.0.2'
  gem 'database_cleaner'
  gem 'coveralls', '0.7.0', require: false
  gem 'poltergeist', '1.5.1'
  gem 'faker', '1.4.3'

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
  if File.exist?(".dev")
    platforms :mri_19 do
      gem 'debugger'
      gem 'debugger-ruby_core_source'
    end

    platforms :mri_20, :mri_21 do
      gem 'byebug'
    end

    platforms :mri_19, :mri_20, :mri_21 do
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

# Load additional gems from "Gemfile.local" if it exists
eval_gemfile "Gemfile.local" if File.exist?("Gemfile.local")
