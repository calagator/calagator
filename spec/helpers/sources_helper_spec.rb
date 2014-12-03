require "spec_helper"

describe SourcesHelper, :type => :helper do
  describe "#source_url_link" do
    it "returns an unspiderable link that opens in a new window" do
      source = double(url: "http://google.com")
      expect(helper.source_url_link(source)).to eq(
        %(<a href="http://google.com" rel="nofollow" target="_BLANK">http://google.com</a>)
      )
    end
  end
end
