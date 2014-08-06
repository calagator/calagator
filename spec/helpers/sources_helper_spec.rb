require "spec_helper"

describe SourcesHelper do
  describe "#source_url_link" do
    it "returns an unspiderable link that opens in a new window" do
      source = double(url: "http://google.com")
      helper.source_url_link(source).should ==
        %(<a href="http://google.com" rel="nofollow" target="_BLANK">http://google.com</a>)
    end
  end
end
