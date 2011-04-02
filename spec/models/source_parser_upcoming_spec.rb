require File.dirname(__FILE__) + '/../spec_helper'

describe SourceParser::Upcoming do
  fixtures :events, :venues

  describe "when extracting Upcoming event id" do
    it 'should extract from verbose URL' do
      SourceParser::Upcoming._upcoming_url_to_event_id('http://upcoming.yahoo.com/event/3082817/OR/Portland/Ignite-Portland-7/').should == '3082817'
    end

    it "should extract from terse URL" do
      SourceParser::Upcoming._upcoming_url_to_event_id('http://upcoming.yahoo.com/event/3082817/').should == '3082817'
    end

    it "should extract from truncated URL" do
      SourceParser::Upcoming._upcoming_url_to_event_id('http://upcoming.yahoo.com/event/3082817').should == '3082817'
    end

    it "should extract from mobile URL" do
      SourceParser::Upcoming._upcoming_url_to_event_id('http://m.upcoming.yahoo.com/event/3082817').should == '3082817'
    end
  end

  it "should parse" do
    content = read_sample('upcoming_ip7.xml')
    events = SourceParser::Upcoming.to_abstract_events(:content => content,
                                                       :url => 'http://upcoming.yahoo.com/event/3082817')

    events.size.should == 1
    event = events.first
    location = event.location

    event.title.should == 'Ignite Portland 7'
    event.description.should =~ /^NEW DATE.+Ignite Portland 7 will happen/m
    event.start_time.should == Time.parse('2009-11-19 7:00PM')
    event.end_time.should == Time.parse('2009-11-19 10:00PM')
    event.url.should == 'http://www.igniteportland.com'
    event.tags.should == ['upcoming:event=3082817']

    location.street_address.should == '3702 S.E. Hawthorne Blvd'
    location.locality.should == 'Portland'
    location.region.should == 'Oregon'
    location.postal_code.should == '97214'
  end
end
