require 'spec_helper'

module Calagator

describe ApplicationHelper, :type => :helper do
  describe "#format_description" do
    it "should autolink" do
      expect(helper.format_description("foo http://mysite.com/~user bar")).to eq \
        '<p>foo <a href="http://mysite.com/~user">http://mysite.com/~user</a> bar</p>'
    end

    it "should process Markdown links" do
      expect(helper.format_description("[ClojureScript](https://github.com/clojure/clojurescript), the Clojure to JS compiler")).to eq \
        '<p><a href="https://github.com/clojure/clojurescript">ClojureScript</a>, the Clojure to JS compiler</p>'
    end

    it "should process Markdown references" do
      expect(helper.format_description("
[SocketStream][1], a phenomenally fast real-time web framework for Node.js

[1]: https://github.com/socketstream/socketstream
      ")).to eq \
        '<p><a href="https://github.com/socketstream/socketstream">SocketStream</a>, a phenomenally fast real-time web framework for Node.js</p>'
    end
  end

  describe "#source_code_version" do
    it "returns the gem version" do
      expect(helper.source_code_version).to eq(Calagator::VERSION)
    end
  end

  describe "#datestamp" do
    it "constructs a sentence describing the item's history" do
      event = FactoryGirl.create(:event, created_at: "2010-01-01", updated_at: "2010-01-02")
      event.create_source! title: "google", url: "http://google.com"
      allow(event.source).to receive_messages id: 1
      expect(helper.datestamp(event)).to eq(
        %(This item was imported from <a href="/sources/1">google</a> <br />) +
        %(<strong>Friday, January 1, 2010 at midnight</strong> ) +
        %(and last updated <br /><strong>Saturday, January 2, 2010 at midnight</strong>.)
      )
    end
  end
end

end
