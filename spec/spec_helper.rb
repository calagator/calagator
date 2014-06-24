# This file is copied to spec/ when you run 'rails generate rspec:install'

# Calagator:
ENV['RAILS_ENV'] = 'test' if ENV['RAILS_ENV'].to_s.empty? || ENV['RAILS_ENV'] == 'development'

require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

# Calagator: Load this project's custom spec extensions:
require File.expand_path(File.dirname(__FILE__) + '/spec_helper_extensions.rb')

RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec do |mocks|
    mocks.syntax = [:should, :expect]
  end

  config.expect_with :rspec do |expectations|
    expectations.syntax = [:should, :expect]
  end

  # Filter out gems from backtraces
  config.backtrace_exclusion_patterns << /vendor\//
  config.backtrace_exclusion_patterns << /lib\/rspec\/rails/
  config.backtrace_exclusion_patterns << /gems\//

  # Disable these so transactions can be used by the database cleaner
  config.use_transactional_fixtures = false

  # Database cleaner
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:deletion)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  # rspec-rails 3 will no longer automatically infer an example group's spec type
  # from the file location. You can explicitly opt-in to the feature using this
  # config option.
  # To explicitly tag specs without using automatic inference, set the `:type`
  # metadata manually:
  #
  #     describe ThingsController, :type => :controller do
  #       # Equivalent to being in spec/controllers
  #     end
  config.infer_spec_type_from_file_location!
end
