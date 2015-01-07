require "webmock/rspec"

RSpec.configure do |config|
  config.before(:suite) do
    # poltergeist and solr need to connect to localhost
    WebMock.disable_net_connect!(allow_localhost: true)
  end
end
