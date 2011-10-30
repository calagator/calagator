require 'spec_helper'
include ApplicationHelper

describe ApplicationHelper do
  describe "when escaping HTML while preserving entities (cleanse)" do
    it "should preserve plain text" do
      cleanse("Allison to Lillia").should == "Allison to Lillia"
    end

    it "should escape HTML" do
      cleanse("<Fiona>").should == "&lt;Fiona&gt;"
    end

    it "should preserve HTML entities" do
      cleanse("Allison &amp; Lillia").should == "Allison &amp; Lillia"
    end

    it "should handle text, HTML and entities together" do
      cleanse("&quot;<Allison> &amp; Lillia&quot;").should == "&quot;&lt;Allison&gt; &amp; Lillia&quot;"
    end
  end

  describe "#helper.mobile_stylesheet_media" do
    def mobile_cookie(value=nil)
      cookie_name = ApplicationController::MOBILE_COOKIE_NAME
      if value
        @request.cookies[cookie_name] = value
      end
      return @request.cookies[cookie_name]
    end

    before :each do
      @request.cookies.delete(:mobile)
    end

    after :each do
      @request.cookies.delete(:mobile)
    end

    it "should use default media if no overrides in params or cookies were specified" do
      helper.mobile_stylesheet_media("hello").should == "hello"
    end

    it "should force rendering of mobile site if given a param of '1' and save it as cookie" do
      controller.params[:mobile] = "1"

      helper.mobile_stylesheet_media("hello").should == :all

      mobile_cookie.should == "1"
    end

    it "should force rendering of non-mobile site if given a param of '0' and save it as cookie" do
      controller.params[:mobile] = "0"

      helper.mobile_stylesheet_media("hello").should == false

      mobile_cookie.should == "0"
    end

    it "should use default media if given a param of '' and clear :mobile cookie" do
      mobile_cookie "1"
      controller.params[:mobile] = "-1"

      helper.mobile_stylesheet_media("hello").should == "hello"

      mobile_cookie.should be_nil
    end

    it "should use mobile rendering if cookie's mobile preference is set to '1'" do
      mobile_cookie "1"

      helper.mobile_stylesheet_media("hello").should == :all

      mobile_cookie.should == "1"
    end

    it "should use non-mobile rendering if cookie's mobile preference is set to '0'" do
      mobile_cookie "0"

      helper.mobile_stylesheet_media("hello").should == false

      mobile_cookie.should == "0"
    end
  end

  describe "#format_description" do
    it "should autolink" do
      helper.format_description("foo http://mysite.com/~user bar").should ==
        '<p>foo <a href="http://mysite.com/~user">http://mysite.com/~user</a> bar</p>'
    end

    it "should process Markdown links" do
      helper.format_description("[ClojureScript](https://github.com/clojure/clojurescript), the Clojure to JS compiler").should ==
        '<p><a href="https://github.com/clojure/clojurescript">ClojureScript</a>, the Clojure to JS compiler</p>'
    end

    it "should process Markdown references" do
      helper.format_description("
[SocketStream][1], a phenomenally fast real-time web framework for Node.js

[1]: https://github.com/socketstream/socketstream
      ").should ==
        '<p><a href="https://github.com/socketstream/socketstream">SocketStream</a>, a phenomenally fast real-time web framework for Node.js</p>'
    end
  end
end
