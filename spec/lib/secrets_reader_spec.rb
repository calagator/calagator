describe SecretsReader do
  describe ".read" do
    let(:yml) { <<-YML }
      administrator_email: 'your@email.addr'
      mapping:
        marker_color: green
        google_maps_api_key: <your google maps v3 API key>
    YML
        
    it "returns an openstruct read from the given file path" do
      path = "myfile.yml"
      allow(File).to receive(:exist?).with(path).and_return(true)
      allow(File).to receive(:read).with(path).and_return(yml)

      expect(SecretsReader.read(path)).to eq OpenStruct.new({
        "administrator_email" => "your@email.addr",
        "mapping" => {
          "marker_color" => "green",
          "google_maps_api_key" => "<your google maps v3 API key>",
        }
      })
    end
        
    it "defaults to config/secrets.yml" do
      path = Rails.root.join("config/secrets.yml").to_s
      allow(File).to receive(:exist?).with(path).and_return(true)
      allow(File).to receive(:read).with(path).and_return(yml)

      expect(SecretsReader.read).to eq OpenStruct.new({
        "administrator_email" => "your@email.addr",
        "mapping" => {
          "marker_color" => "green",
          "google_maps_api_key" => "<your google maps v3 API key>",
        }
      })
    end
        
    it "will fall back to config/secrets.yml.sample" do
      default_path = Rails.root.join("config/secrets.yml").to_s
      allow(File).to receive(:exist?).with(default_path).and_return(false)

      path = Rails.root.join("config/secrets.yml.sample").to_s
      allow(File).to receive(:exist?).with(path).and_return(true)
      allow(File).to receive(:read).with(path).and_return(yml)

      expect(SecretsReader.read).to eq OpenStruct.new({
        "administrator_email" => "your@email.addr",
        "mapping" => {
          "marker_color" => "green",
          "google_maps_api_key" => "<your google maps v3 API key>",
        }
      })
    end

    it "returns an empty openstruct if all fails" do
      default_path = Rails.root.join("config/secrets.yml").to_s
      allow(File).to receive(:exist?).with(default_path).and_return(false)

      path = Rails.root.join("config/secrets.yml.sample").to_s
      allow(File).to receive(:exist?).with(path).and_return(false)

      expect(SecretsReader.read).to eq OpenStruct.new
    end
  end
end
