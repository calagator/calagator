source :rubygems

# Load additional gems from "Gemfile.local" if it exists, has same format as this file.
begin
  data = File.read('Gemfile.local')
rescue Errno::ENOENT
  # Ignore
end
eval data if data

# Database driver
gem 'sqlite3'

# Run-time dependencies
gem 'rails', '3.0.7'
gem 'columnize', '0.3.4'
gem 'rdoc', '3.8', :require => nil
gem 'geokit', '1.5.0'
gem 'htmlentities', '4.2.3'
gem 'linecache', '0.46'
gem 'paper_trail', '2.2.4'
gem 'ri_cal', '0.8.7'
gem 'rubyzip', '0.9.4', :require =>  'zip/zip'
gem 'will_paginate', '2.3.15'
gem 'httparty', '0.7.8'
gem 'loofah', '1.0.0'
gem 'loofah-activerecord', '1.0.0'
gem 'bluecloth', '2.1.0'

gem 'themes_for_rails', '0.4.2'

# NOTE: mofo 0.2.9 and above are evil, defining their own defective Object#try method and are unable to extract "postal-code" address fields from hCalendar. Mofo is used in Calagator's SourceParser::Hcal and throughout for String#strip_html. The library has been abandoned and its author recommends switching to the incompatible "prism" gem.
gem 'mofo', '0.2.8'

# Some dependencies are only needed for test and development environments. On
# production servers, you can skip their installation by running:
#   bundle install --without development test
group :development, :test do
  gem 'rspec-rails', '2.6.0'
  gem 'rcov', '0.9.9', :require => false
  gem 'factory_girl', '1.3.3'

  case RUBY_VERSION.to_f
  when 1.9..2.0
    gem "ruby-debug19", :require => "ruby-debug"
  when 1.8..1.9
    gem "ruby-debug"
  end
end

# Some dependencies are activated through server settings.
require 'lib/secrets_reader'
secrets = SecretsReader.read(:silent => true)
case secrets.search_engine
when 'sunspot'
  gem 'sunspot', '1.2.1', :require => 'sunspot'
  gem 'sunspot_rails', '1.2.1', :require  => 'sunspot/rails'
end
