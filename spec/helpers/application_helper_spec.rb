require 'spec_helper'

describe ApplicationHelper, :type => :helper do
  describe "when escaping HTML while preserving entities (cleanse)" do
    it "should preserve plain text" do
      expect(cleanse("Allison to Lillia")).to eq "Allison to Lillia"
    end

    it "should escape HTML" do
      expect(cleanse("<Fiona>")).to eq "&lt;Fiona&gt;"
    end

    it "should preserve HTML entities" do
      expect(cleanse("Allison &amp; Lillia")).to eq "Allison &amp; Lillia"
    end

    it "should handle text, HTML and entities together" do
      expect(cleanse("&quot;<Allison> &amp; Lillia&quot;")).to eq "&quot;&lt;Allison&gt; &amp; Lillia&quot;"
    end
  end

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

  describe "the source code version date" do
    it "returns the timestamp from git" do
      expect(ApplicationHelper).to receive(:system).with(/git/).and_return(true)
      expect(ApplicationHelper).to receive(:`).with(/git/).and_return("Tue Jul 29 01:22:49 2014 -0700")
      expect(ApplicationHelper.source_code_version_raw).to match(/Git timestamp: Tue Jul 29 01:22:49 2014 -0700/)
    end

    describe "when the git command can't be found" do
      it "returns empty string" do
        expect(ApplicationHelper).to receive(:system).with(/git/).and_return(true)
        expect(ApplicationHelper).to receive(:`).with(/git/).and_raise(Errno::ENOENT)
        expect(ApplicationHelper.source_code_version_raw).to eq("")
      end
    end

    describe "when the git command returns a non-zero exit status" do
      it "returns empty string" do
        expect(ApplicationHelper).to receive(:system).with(/git/).and_return(false)
        expect(ApplicationHelper.source_code_version_raw).to eq("")
      end
    end
  end

  describe "#datestamp" do
    it "constructs a sentence describing the item's history" do
      event = FactoryGirl.create(:event, created_at: "2010-01-01", updated_at: "2010-01-02")
      event.create_source! title: "google", url: "http://google.com"
      allow(event.source).to receive_messages id: 1
      expect(datestamp(event)).to eq(
        %(This item was imported from <a href="/sources/1">google</a> <br />) +
        %(<strong>Friday, January 1, 2010 at midnight</strong> ) +
        %(and last updated <br /><strong>Saturday, January 2, 2010 at midnight</strong>.)
      )
    end
  end
end
