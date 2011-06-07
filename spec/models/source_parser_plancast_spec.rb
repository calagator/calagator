require File.dirname(__FILE__) + '/../spec_helper'

describe SourceParser::Plancast do
  fixtures :all

  it "should tag Plancast events with automagic machine tags" do
    content = read_sample('plancast.ics')
    SourceParser::Base.should_receive(:read_url).and_return(content)
    events = SourceParser::Plancast.to_abstract_events(:content => content,
                                                       :url => 'http://plancast.com/p/5px4/pdx11-civic-hackathon')

    events.size.should == 1
    events.first.tags.should == ["plancast:plan=5px4"]
  end

end
