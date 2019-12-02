require 'webmock/rspec'

RSpec.configure do |config|
  config.before(:suite) do
    WebMock.disable_net_connect!(
      allow_localhost: true, # poltergeist and solr need to connect to localhost
      allow: 'chromedriver.storage.googleapis.com' # webdrivers needs to download chromedriver
    )
  end
end
