source :rubygems

gem 'sqlite3'

gem 'rails', '2.3.11'
gem 'columnize', '0.3.2'
gem 'geokit', '1.5.0'
gem 'hpricot', '0.8.3'
gem 'htmlentities', '4.2.3'
gem 'linecache', '0.43'
gem 'paper_trail', '1.6.4'
gem 'ri_cal', '0.8.7'
gem 'rubyzip', '0.9.4', :require =>  'zip/zip'
gem 'will_paginate', '2.3.15'

# NOTE: mofo 0.2.9 and above are evil, defining their own defective Object#try method and are unable to extract "postal-code" address fields from hCalendar. Mofo is used in Calagator's SourceParser::Hcal and throughout for String#strip_html. The library has been abandoned and its author recommends switching to the incompatible "prism" gem.
gem 'mofo', '0.2.8'

# Some dependencies are only needed for test and development environments. On
# production servers, you can skip their installation by running: 
#   bundle install --without development test
group :development, :test do
  gem 'rspec', '1.3.1', :require => false
  gem 'rspec-rails', '1.3.3', :require => false
  gem 'annotate-models', '1.0.4', :require => false
end

# Some dependencies are activated through server settings.
require 'lib/secrets_reader'
secrets = SecretsReader.read(:silent => true)
case secrets.search_engine
when 'sunspot'
  gem 'sunspot', '1.2.1', :require => 'sunspot'
  gem 'sunspot_rails', '1.2.1', :require  => 'sunspot/rails'
end
