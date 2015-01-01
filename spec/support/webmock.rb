require "webmock/rspec"

RSpec.configure do |config|
  config.before do
    # poltergeist requires this
    WebMock.disable_net_connect!(allow_localhost: true)
  end
end
