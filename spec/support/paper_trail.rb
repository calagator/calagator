require "paper_trail/frameworks/rspec"

RSpec.configure do |config|
  config.before do
    PaperTrail.enabled = true
  end
end
