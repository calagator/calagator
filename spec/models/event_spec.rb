require File.dirname(__FILE__) + '/../spec_helper'

describe Event, "in general" do

  it "should be valid" do
    event = Event.new(:title => "Event title", :start_time => Time.parse('2008.04.12'))
    event.should be_valid
  end
  
  it "should add a http:// prefix to urls without one" do
    event = Event.new(:title => "Event title", :start_time => Time.parse('2008.04.12'), :url => 'google.com')
    event.should be_valid
  end

end

describe Event, "when parsing" do

  before(:each) do
    @event = Event.new

    @basic_hcal = read_sample('hcal_basic.xml')
    @basic_venue = mock_model(Venue, :title => 'Argent Hotel, San Francisco, CA')
    @basic_event = Event.new(
      :title => 'Web 2.0 Conference',
      :url => 'http://www.web2con.com/',
      :start_time => Time.parse('2007-10-05'),
      :end_time => nil,
      :venue => @basic_venue)
  end

  it "should parse an AbstractEvent into an Event" do
    event = Event.new(:title => "EventTitle", 
                      :description => "EventDescription", 
                      :start_time => Time.parse("2008-05-20"), 
                      :end_time => Time.parse("2008-05-22"))
    Event.should_receive(:new).and_return(event)
    
    abstract_event = SourceParser::AbstractEvent.new("EventTitle", "EventDescription", Time.parse("2008-05-20"), Time.parse("2008-05-22"))

    Event.from_abstract_event(abstract_event).should == event
  end

  it "should parse an Event into an hCalendar" do
    actual_hcal = @basic_event.to_hcal
    actual_hcal.should =~ Regexp.new(@basic_hcal.gsub(/\s+/, '\s+')) # Ignore spacing changes
  end

  it "should parse an Event into an iCalendar" do
    actual_ical = @basic_event.to_ical

    abstract_events = SourceParser.to_abstract_events(:content => actual_ical, :skip_old => false)

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

    abstract_events = SourceParser.to_abstract_events(:content => actual_ical, :skip_old => false)

    abstract_events.size.should == 1
    abstract_event = abstract_events.first
    abstract_event.title.should == @basic_event.title
    abstract_event.url.should == generated_url

    # TODO implement venue generation
    #abstract_event.location.title.should == @basic_event.venue.title
    abstract_event.location.should be_nil
  end

end

describe Event, "when processing date" do

  before(:each) do
    @event = Event.new
  end
  
  it "should find all events within a given date range" do
    Event.should_receive(:find).with(:all, 
      :conditions => ["events.duplicate_of_id is NULL AND start_time >= ? AND start_time <= ?", Time.parse(Date.today.to_s), Time.parse(Date.tomorrow.to_s)+1.day-1.second], 
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
    @event.start_time = Time.now
    @event.end_time = @event.start_time - 2.hours
    @event.save.should be_false
    @event.should have(1).error_on(:end_time)
  end
  
  it "should return an end time, based on duration" do
    @event.start_time = Time.now
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

describe Event, "when finding by dates" do
  
  before(:all) do
    @now = Time.now
    @event = Event.new(:title => "Event in progress", :start_time => @now - 2.days, :end_time => @now + 2.days)
    @event.save!
    @midnight_start = Event.new(:title => "Midnight start", :start_time => Time.now.beginning_of_day, :end_time => @now + 2.days)
    @midnight_start.save
 end
  
  it "Overview should include events that started earlier today" do
    @events = Event.select_for_overview[:today]
    @events.should include(@midnight_start)
  end
  
  it "Future Events should include events that started earlier today" do
    @events = Event.find_future_events
    @events.should include(@midnight_start)
  end
  
  it "Date Range should include events that started earlier today" do
    @events = Event.find_by_dates(Time.now.beginning_of_day, Time.now+1.day, order = "start_time")
    @events.should include(@midnight_start)
  end
  
  it "should include ongoing events as future events" do
    pending "should include ongoing events as future events"
    @events = Event.find_future_events("start_time")
    @events.should include(@event)
  end
  
  it "should include, within a date range, events ongoing at the start of the range" do
    pending "should include, within a date range, events ongoing at the start of the range"
    @events = Event.find_by_dates(@now - 1.days, @now + 1.days)
    @events.should include(@event)
  end
  
end

describe Event, "when searching" do
  # TODO figure out sane way to write spec for Event.search
  it "should find events" do
    solr_response = mock_model(Object, :results => [])
    solr_return = mock_model(Object, :response => solr_response)
    Event.should_receive(:find_by_solr).and_return(solr_response)

    Event.search("myquery").should be_empty
  end

  it "should find events and group them" do
    current_event = mock_model(Event, :current? => true, :duplicate_of_id => nil)
    past_event = mock_model(Event, :current? => false, :duplicate_of_id => nil)
    solr_response = mock_model(Object, :results => [current_event, past_event])
    solr_return = mock_model(Object, :response => solr_response)
    Event.should_receive(:find_by_solr).and_return(solr_response)

    Event.search_grouped_by_currentness("myquery").should == {
      :current => [current_event],
      :past    => [past_event],
    }
  end
end
