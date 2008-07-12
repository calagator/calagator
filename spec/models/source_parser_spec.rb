require File.dirname(__FILE__) + '/../spec_helper'

class SourceParser::FakeParser < SourceParser::Base
end

describe SourceParser, "when reading content" do
  it "should read from a normal URL" do
    uri = mock_model(URI)
    uri.should_receive(:respond_to?).and_return(true)
    uri.should_receive(:read).and_return(42)
    URI.should_receive(:parse).and_return(uri)

    SourceParser.read_url("not://a.real/~url").should == 42
  end

  it "should read from a wacky URL" do
    uri = mock_model(URI)
    uri.should_receive(:respond_to?).any_number_of_times.and_return(false)
    URI.should_receive(:parse).any_number_of_times.and_return(uri)

    error_type = RUBY_PLATFORM.match(/mswin/) ? Errno::EINVAL : Errno::ENOENT
    lambda { SourceParser.read_url("not://a.real/~url") }.should raise_error(error_type)
  end

  it "should unescape ATOM feeds" do
    content = mock_model(String, :content_type => "application/atom+xml")
    SourceParser::Base.should_receive(:read_url).and_return(content)
    CGI.should_receive(:unescapeHTML).and_return(42)

    SourceParser.content_for(:fake => :argument).should == 42
  end
end

describe SourceParser, "when subclassing" do
  it "should demand that to_hcals is implemented" do
    lambda{ SourceParser::FakeParser.to_hcals }.should raise_error(NotImplementedError)
  end

  it "should demand that to_abstract_events is implemented" do
    lambda{ SourceParser::FakeParser.to_abstract_events }.should raise_error(NotImplementedError)
  end
end

describe SourceParser, "when parsing events" do
  it "should skip past parsing errors" do
    events = [mock_model(SourceParser::AbstractEvent)]
    SourceParser::FakeParser.should_receive(:to_abstract_events).and_raise(NotImplementedError)
    SourceParser::Hcal.should_receive(:to_abstract_events).and_return(events)
    SourceParser::Base.should_receive(:content_for).and_return("fake content")

    SourceParser.to_abstract_events(:fake => :argument).should == events
  end
end
