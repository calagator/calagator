require File.dirname(__FILE__) + '/../spec_helper'

describe SourceParser::Plancast do
  fixtures :all

  it "should tag Plancast events with automagic machine tags" do
    content = read_sample('plancast.ics')
    events = SourceParser::Plancast.to_abstract_events(:content => content,
                                                       :url => 'http://plancast.com/p/5px4/pdx11-civic-hackathon')

    events.size.should == 1
    events.first.tags.should == ["plancast:plan=5px4"]
  end

end