require File.dirname(__FILE__) + '/../spec_helper'

describe SourceParser::Hcal, "with hCalendar events" do
  fixtures :events, :venues

  it "should parse hcal" do
    hcal_content = read_sample('hcal_single.xml')
    hcal_source = Source.new(:title => "Calendar event feed", :url => "http://mysample.hcal/")
    SourceParser::Base.should_receive(:read_url).and_return(hcal_content)

    events = hcal_source.to_events

    events.size.should == 1
    for key, value in {
      :title => "Calendar event",
      :description => "Check it out!",
      :start_time => Time.parse("2008-1-19"),
      :end_time => Time.parse("2008-1-20"),
      :url => "http://www.cubespacepdx.com",
      :venue_id => nil, # TODO what should venue instance be?
    }
      events.first.send(key).should == value
    end
  end

  it "should strip html from the venue title" do
    hcal_content = read_sample('hcal_upcoming_v1.html')
    hcal_source = Source.new(:title => "Calendar event feed", :url => "http://mysample.hcal/")
    SourceParser::Base.stub!(:read_url).and_return(hcal_content)
    events = hcal_source.to_events

    events.first.venue.title.should == 'Jive Software Office'
  end

  it "should parse a page with multiple events" do
    hcal_content = read_sample('hcal_multiple.xml')

    hcal_source = Source.new(:title => "Calendar event feed", :url => "http://mysample.hcal/")
    SourceParser::Base.should_receive(:read_url).and_return(hcal_content)

    events = hcal_source.to_events
    events.size.should == 2
    first, second = *events
    first.start_time.should == Time.parse('2008-1-19')
    first.end_time.should == Time.parse('2008-01-20')
    second.start_time.should == Time.parse('2008-2-2')
    second.end_time.should == Time.parse('2008-02-03')
  end
end

describe SourceParser::Hcal, "with hCalendar to AbstractLocation parsing" do
  it "should extract an AbstractLocation from an hCalendar text" do
    hcal_upcoming = read_sample('hcal_upcoming_v1.html')

    SourceParser::Hcal.stub!(:read_url).and_return(hcal_upcoming)
    abstract_events = SourceParser::Hcal.to_abstract_events(:url => "http://foo.bar/")
    abstract_event = abstract_events.first
    abstract_location = abstract_event.location

    abstract_location.should be_a_kind_of(SourceParser::AbstractLocation)
    abstract_location.locality.should == "portland"
    abstract_location.street_address.should == "317 SW Alder St Ste 500"
    abstract_location.latitude.should be_close(45.5191, 0.1)
    abstract_location.longitude.should be_close(-122.675, 0.1)
    abstract_location.postal_code.should == "97204"
  end
end

describe SourceParser::Hcal, 'when parsing Upcoming' do
  def prepare(sample_filename)
    @content = read_sample(sample_filename)
    @events = SourceParser::Hcal.to_abstract_events(:content => @content)
    @event = @events.first
    @location = @event.location
  end

  describe 'shared', :shared => true do
    it 'should have exactly one event' do
      @events.size.should == 1
    end

    it 'should have an event' do
      @event.should be_a_kind_of(SourceParser::AbstractEvent)
    end

    it 'should have a location' do
      @location.should be_a_kind_of(SourceParser::AbstractLocation)
    end
  end

  describe 'v1 data' do
    it_should_behave_like 'shared'

    before(:all) do
      prepare 'hcal_upcoming_v1.html'
    end

    it 'should have the expected event' do
      @event.title.should == 'February BarCamp Portland Informal Tech Meetup'
      @event.description.should =~ /The intent is to get a group of cool people/
      # FIXME why is start_time a Time, while end_time is a String?!
      @event.start_time.should == Time.parse('2008-02-28 5:30PM PST').to_s
      @event.end_time.should == Time.parse('2008-02-28 7:30PM PST')
      @event.url.should == 'http://barcamp.org/BarCampPortlandMeetups'
    end

    it 'should have the expected location' do
      @location.title.should == 'Jive Software Office'
      @location.description.should be_blank
      @location.address.should be_blank
      @location.street_address.should == '317 SW Alder St Ste 500'
      @location.locality.should == 'portland'
      @location.region.should be_blank
      @location.postal_code.should == '97204'
      @location.latitude.should be_close(45.5191, 0.1)
      @location.longitude.should be_close(-122.675, 0.1)
      @location.url.should be_blank
      @location.email.should be_blank
      @location.telephone.should be_blank
    end
  end

  describe 'v2 data' do
    it_should_behave_like 'shared'

    before(:all) do
      prepare 'hcal_upcoming_v2.html'
    end

    it 'should have the expected event' do
      @event.title.should == 'Ignite Portland 4'
      @event.description.should =~ /Save the date! Ignite Portland 4 will happen/
      # TODO why is start_time a Time, while end_time is a String?!
      @event.start_time.should == Time.parse('2008-11-13 7:00PM PST').to_s
      @event.end_time.should == Time.parse('2008-11-13 9:00PM PST')
      @event.url.should == 'http://www.igniteportland.com'
    end

    it 'should have the expected location' do
      @location.title.should == 'Bagdad Theater and Pub'
      @location.description.should be_blank
      @location.address.should be_blank
      @location.street_address.should == '3702 S.E. Hawthorne Blvd'
      @location.locality.should == 'Portland'
      @location.region.should == 'Oregon'
      @location.postal_code.should == '97214'
      @location.latitude.should be_blank
      @location.longitude.should be_blank
      @location.url.should be_blank
      @location.email.should be_blank
      @location.telephone.should be_blank
    end
  end

  describe 'v3 data' do
    it_should_behave_like 'shared'

    before(:all) do
      prepare 'hcal_upcoming_v3.html'
    end

    it 'should have the expected event' do
      @event.title.should == 'Ignite Portland 5'
      @event.description.should =~ /Save the date! Ignite Portland 5 will happen/
      # TODO why is start_time a Time, while end_time is a String?!
      @event.start_time.should == Time.parse('2009-02-19 7:00PM PST').to_s
      @event.end_time.should be_nil # This specific event has no DTEND
      @event.url.should == 'http://www.igniteportland.com'
    end

    it 'should have the expected location' do
      @location.title.should == 'Bagdad Theater and Pub'
      @location.description.should be_blank
      @location.address.should be_blank
      @location.street_address.should == '3702 S.E. Hawthorne Blvd'
      @location.locality.should == 'Portland'
      @location.region.should == 'Oregon'
      @location.postal_code.should == '97214'
      @location.latitude.should be_blank
      @location.longitude.should be_blank
      @location.url.should be_blank
      @location.email.should be_blank
      @location.telephone.should be_blank
    end
  end

  describe 'v4 data' do
    it_should_behave_like 'shared'

    before(:all) do
      prepare 'hcal_upcoming_v4.html'
    end

    it 'should have the expected event' do
      @event.title.should == 'Lunch 2.0 Party Train to OTBC'
      @event.description.should =~ /Here('|&#39;)s the scoop: Meet up at Pioneer Square/
      # TODO why is start_time a Time, while end_time is a String?!
      @event.start_time.should == Time.parse('2009-01-14 11:00AM PST').to_s
      @event.end_time.should be_nil # This specific event has no DTEND
      @event.url.should be_nil
    end

    it 'should have the expected location' do
      @location.title.should == 'Pioneer Courthouse Square'
      @location.description.should be_blank
      @location.address.should be_blank
      @location.street_address.should == '701 Sw 6th Ave'
      @location.locality.should == 'Portland'
      @location.region.should == 'Oregon'
      @location.postal_code.should == '97204'
      @location.latitude.should be_blank
      @location.longitude.should be_blank
      @location.url.should be_blank
      @location.email.should be_blank
      @location.telephone.should be_blank
    end
  end
end
