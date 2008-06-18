require File.dirname(__FILE__) + '/../spec_helper'

describe SourceParser::Ical, "in general" do
  it "should read http URLs as-is" do
    http_url = "http://foo.bar/"
    uri = mock_model(URI, :read => 42)
    URI.should_receive(:parse).with(http_url).and_return(uri)

    SourceParser::Ical.read_url(http_url).should == 42
  end

  it "should read webcal URLs as http" do
    webcal_url = "webcal://foo.bar/"
    http_url   = "http://foo.bar/"
    uri = mock_model(URI, :read => 42)
    URI.should_receive(:parse).with(http_url).and_return(uri)

    SourceParser::Ical.read_url(webcal_url).should == 42
  end
end

describe SourceParser::Ical, "when parsing locations" do
  it "should fallback on VPIM errors" do
    invalid_hcard = <<-HERE
BEGIN:VVENUE
omgwtfbbq
END:VVENUE
    HERE

    SourceParser::Ical.to_abstract_location(invalid_hcard, :fallback => "mytitle").title.should == "mytitle"
  end
end
