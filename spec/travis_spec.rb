if ENV["DB"]
  describe "travis matrix" do
    it "should be testing the right db" do
      expect(ActiveRecord::Base.connection_config[:adapter]).to eq ENV["DB"]
    end
  end
end
