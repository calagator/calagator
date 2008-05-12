require File.dirname(__FILE__) + '/../spec_helper'

describe Event do
  
  it "should be valid" do
    event = Event.new(:title => "Event title", :start_time => Time.parse('2008.04.12'))
    event.should be_valid
  end
  
  it "should add a http:// prefix to urls without one" do
    event = Event.new(:title => "Event title", :start_time => Time.parse('2008.04.12'), :url => 'google.com')
    event.should be_valid
  end
  
end

describe Event do
  before(:each) do
    @event = Event.new

    @basic_hcal = read_sample('hcal_basic.xml')
    @basic_venue = mock_model(Venue, :title => 'Argent Hotel, San Francisco, CA')
    @basic_event = Event.new(
      :title => 'Web 2.0 Conference',
      :url => 'http://www.web2con.com/',
      :start_time => Time.parse('2007-10-05'),
      :venue => @basic_venue)
  end

  it "should parse an AbstractEvent into an Event" do
    event = Event.new(:title => "EventTitle", 
                      :description => "EventDescription", 
                      :start_time => Date.parse("2008-05-20"), 
                      :end_time => Date.parse("2008-05-22"))
    Event.should_receive(:new).and_return(event)
    
    abstract_event = SourceParser::AbstractEvent.new("EventTitle", "EventDescription", Date.parse("2008-05-20"), Date.parse("2008-05-22"))

    Event.from_abstract_event(abstract_event).should == event
  end

  it "should parse an Event into an hCalendar" do
    actual_hcal = @basic_event.to_hcal
    actual_hcal.should =~ Regexp.new(@basic_hcal.gsub(/\s+/, '\s+')) # Ignore spacing changes
  end

  it "should parse an Event into an iCalendar" do
    actual_ical = @basic_event.to_ical

    abstract_events = SourceParser.to_abstract_events(:content => actual_ical)

    abstract_events.size.should == 1
    abstract_event = abstract_events.first
    abstract_event.title.should == @basic_event.title
    abstract_event.url.should == @basic_event.url

    # TODO implement venue generation
    #abstract_event.location.title.should == @basic_event.venue.title
    abstract_event.location.should be_nil
  end

  it "should parse an Event into an iCalendar without a URL and generate it" do
    generated_url = "http://foo.bar/"
    @basic_event.url = nil
    actual_ical = @basic_event.to_ical(:url_helper => lambda{|event| generated_url})

    abstract_events = SourceParser.to_abstract_events(:content => actual_ical)

    abstract_events.size.should == 1
    abstract_event = abstract_events.first
    abstract_event.title.should == @basic_event.title
    abstract_event.url.should == generated_url

    # TODO implement venue generation
    #abstract_event.location.title.should == @basic_event.venue.title
    abstract_event.location.should be_nil
  end
  
  it "should find all events within a given date range" do
    Event.should_receive(:find).with(:all, :conditions => ['start_time > ? AND start_time < ? AND events.duplicate_of_id is NULL', DateTime.parse(Date.today.to_s), DateTime.parse(Date.tomorrow.to_s)+1.day-1.second], 
        :order => 'start_time',
        :include => :venue)
    Event.find_by_dates(Date.today, Date.tomorrow)
  end
  
  it "should find all events with duplicate titles" do
    Event.should_receive(:find_by_sql).with("SELECT DISTINCT a.* from events a, events b WHERE a.id <> b.id AND ( a.title = b.title ) ORDER BY a.title")
    Event.find_duplicates_by(:title)
  end
  
  it "should find all events with duplicate titles and urls" do
    Event.should_receive(:find_by_sql).with("SELECT DISTINCT a.* from events a, events b WHERE a.id <> b.id AND ( a.title = b.title AND a.url = b.url ) ORDER BY a.title,a.url")
    Event.find_duplicates_by([:title,:url])
  end
  
  it "should fail to validate if end_time is earlier than start time " do
    @event.start_time = DateTime.now
    @event.end_time = @event.start_time - 2.hours
    @event.save.should be_false
    @event.should have(1).error_on(:end_time)
  end
  
  it "should return an end time, based on duration" do
    @event.start_time = DateTime.now
    @event.duration = 60
    @event.end_time.should == @event.start_time + 1.hour
  end
  
  it "should set a duration when given an end time" do
    now  = Time.now
    @event.start_time = now
    @event.end_time = (now + 1.hour)
    @event.duration.should == 60
  end
  
  it "should handle setting end before start" do
    @event = Event.new
    now = Time.now
    @event.end_time = now + 2.hours
    @event.start_time = now
    @event.duration.should == 120
  end
  
  it "should handle setting duration before start" do
    @event = Event.new
    now = Time.now
    @event.duration = 120
    @event.start_time = now
    @event.end_time.should == now + 2.hours
  end
  
  it "should handle changing end time with an existing duration" do
    @event = Event.new
    now = Time.now
    @event.start_time = now
    @event.duration = 60
    @event.end_time = now + 2.hours
    @event.end_time.should == now + 2.hours
  end
  
end
