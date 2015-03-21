require "spec_helper"

describe "Rack config" do
  include Rack::Test::Methods
  let(:app) {
    Rack::Builder.parse_file('config.ru').first
  }
  describe "when RAILS_RELATIVE_URL_ROOT is absent" do
    it "mounts the app to '/'" do
      get '/'
      expect(last_response).to be_ok
    end
  end

  describe "when RAILS_RELATIVE_URL_ROOT is present" do
    let(:new_root) { "/foobar" }

    before do
      @root = ENV["RAILS_RELATIVE_URL_ROOT"]
      ENV["RAILS_RELATIVE_URL_ROOT"] = new_root
    end

    after do
      ENV["RAILS_RELATIVE_URL_ROOT"] = @root
    end

    it "mounts the app to the subdirectory" do
      get new_root
      expect(last_response).to be_ok
    end
  end
end
