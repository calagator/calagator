# frozen_string_literal: true

require "webmock/rspec"

RSpec.configure do |config|
  config.before(:suite) do
    WebMock.disable_net_connect!(
      allow_localhost: true # solr needs to connect to localhost
    )
  end
end
