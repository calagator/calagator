# frozen_string_literal: true

require "spec_helper"

describe Calagator::SourcesHelper, type: :helper do
  describe "#source_url_link" do
    it "returns an unspiderable link that opens in a new window" do
      source = double(url: "http://google.com")
      expect(helper.source_url_link(source)).to match_dom_of \
        %(<a href="http://google.com" rel="nofollow" target="_BLANK">http://google.com</a>)
    end
  end
end
