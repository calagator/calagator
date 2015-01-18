require "spec_helper"
require "url_prefixer"

describe UrlPrefixer do
  it "adds an http prefix to urls missing it" do
    url = UrlPrefixer.prefix("google.com")
    url.should == "http://google.com"
  end

  it "leaves urls with an existing scheme alone" do
    url = UrlPrefixer.prefix("https://google.com")
    url.should == "https://google.com"
  end

  it "leaves blank urls alone" do
    url = UrlPrefixer.prefix(" ")
    url.should == " "
  end

  it "leaves nil urls alone" do
    url = UrlPrefixer.prefix(nil)
    url.should == nil
  end

  it "avoids whitespace inside url" do
    url = UrlPrefixer.prefix(" google.com ")
    url.should == "http://google.com "
  end
end
