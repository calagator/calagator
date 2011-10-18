require 'spec_helper'

describe SourceParser::Upcoming do
  fixtures :all

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

  it "should parse a v1 API response" do
    content = read_sample('upcoming_v1.xml')
    events = SourceParser::Upcoming.to_abstract_events(:content => content,
                                                       :url => 'http://upcoming.yahoo.com/event/3082817')

    events.size.should == 1
    event = events.first
    location = event.location

    event.title.should == 'Ignite Portland 7'
    event.description.should =~ /^NEW DATE.+Ignite Portland 7 will happen/m
    event.start_time.should == Time.parse('2009-11-19 7:00PM')
    # NOTE: Upcoming's API used to emit sensible "utc_end" date-times which the below test relied on, but nothing in the "end_date" or "end_time" fields. However, the v2 API has incorrect "utc_end" date-times and only has "end_date" and "end_time" fields. Therefore, we can't tell when this event ends any more:
    event.end_time.should == nil # Was: Time.parse('2009-11-19 10:00PM')
    event.url.should == 'http://www.igniteportland.com'
    event.tags.should == ['upcoming:event=3082817']

    location.street_address.should == '3702 S.E. Hawthorne Blvd'
    location.locality.should == 'Portland'
    location.region.should == 'Oregon'
    location.postal_code.should == '97214'
    location.tags.should == ['upcoming:venue=61559']
  end

  it "should parse a v2 API response with invalid UTC dates" do
    content = read_sample('upcoming_v2_with_invalid_utc_dates.xml')
    events = SourceParser::Upcoming.to_abstract_events(:content => content,
                                                       :url => 'http://upcoming.yahoo.com/event/8237694')

    events.size.should == 1
    event = events.first
    location = event.location

    event.title.should == "Portland JavaScript Admirers' Monthly Meeting"
    event.description.should =~ /^The monthly meeting of Portland's first JavaScript and ECMAscript users' group./
    event.start_time.should == Time.parse('Oct 26 19:00:00 2011')
    event.end_time.should == Time.parse('Oct 26 21:00:00 2011')
    event.url.should be_blank
    event.tags.should == ['upcoming:event=8237694']

    location.street_address.should == '915 SW Stark St., Suite 400'
    location.locality.should == 'Portland'
    location.region.should == 'Oregon'
    location.postal_code.should == '97205'
    location.tags.should == ['upcoming:venue=591135']
  end
end
