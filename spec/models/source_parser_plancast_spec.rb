require File.dirname(__FILE__) + '/../spec_helper'

describe SourceParser::Plancast do
  fixtures :all

  it "should tag Plancast events with automagic machine tags" do
    content = read_sample('plancast.json')
    HTTParty.should_receive(:get).and_return(Crack::JSON.parse(content))
    events = SourceParser::Plancast.to_abstract_events(:content => content,
                                                       :url => 'http://plancast.com/p/3cos/indiewebcamp',
                                                       :skip_old => false)

    events.size.should == 1
    events.first.tags.should == ["plancast:plan=3cos"]
  end

  it "should create a new venue when structured data is provided"

end
