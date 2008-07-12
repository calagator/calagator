require File.dirname(__FILE__) + '/../spec_helper'

describe Event do
  before(:each) do
    @event = Event.new
  end

  describe "in general"  do
    
    it "should be valid" do
      event = Event.new(:title => "Event title", :start_time => Time.parse('2008.04.12'))
      event.should be_valid
    end
  
    it "should add a http:// prefix to urls without one" do
      event = Event.new(:title => "Event title", :start_time => Time.parse('2008.04.12'), :url => 'google.com')
      event.should be_valid
    end
  end
  
  describe "dealing with tags" do
    before(:each) do
      @tags = "some, tags"
      @event.title = "Tagging Day"
      @event.start_time = Time.now
    end
    
    it "should be taggable" do
      Tag # need to reference Tag class in order to load it.
      @event.tag_list.should == ""
    end
    
    it "should tag itself if it is an extant record" do 
      @event.stub!(:new_record?).and_return(false)
      @event.should_receive(:tag_with).with(@tags).and_return(@event)
      @event.tag_list = @tags
    end
    
    it "should just cache tagging if it is a new record" do
      @event.should_not_receive(:save)
      @event.should_not_receive(:tag_with)
      @event.new_record?.should == true
      @event.tag_list = @tags
      @event.tag_list.should == @tags
    end
    
    it "should tag itself when saved for the first time if there are cached tags" do 
      @event.new_record?.should == true
      @event.should_receive(:tag_with).with(@tags).and_return(@event)
      @event.tag_list = @tags
      @event.save
    end
  
  end

  describe "when parsing" do

    before(:each) do

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

  describe "when processing date" do

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

  end

  describe "when finding by dates" do

    before(:all) do
      @now = Time.now

      @started_before_and_continuing_after = Event.new(
        :title => "Event in progress",
        :start_time => @now - 2.days,
        :end_time => @now + 2.days)
      @started_before_and_continuing_after.save!

      @started_midnight_and_continuing_after = Event.new(
        :title => "Midnight start",
        :start_time => Time.now.beginning_of_day,
        :end_time => @now + 2.days)
      @started_midnight_and_continuing_after.save

      @started_before_and_ended_yesterday = Event.new(
        :title => "Yesterday start",
        :start_time => @now - 2.days,
        :end_time => Time.now.beginning_of_day-1.second)
      @started_before_and_ended_yesterday.save!
   end

    describe "for overview" do
      it "should include ongoing events" do
        events = Event.select_for_overview[:today]
        events.should include(@started_midnight_and_continuing_after)
      end

      it "should not include past events" do
        events = Event.select_for_overview[:today]
        events.should_not include(@started_before_and_ended_yesterday)
      end
    end

    describe "for future events" do
      it "should include ongoing events" do
        events = Event.find_future_events
        events.should include(@started_midnight_and_continuing_after)
      end

      # TODO figure out what this example was intended to do
      #it "should include ongoing events as future events" do
      #  pending "should include ongoing events as future events"
      #  events = Event.find_future_events("start_time")
      #  events.should include(@started_before_and_continuing_after)
      #end

      it "should not include past events" do
        events = Event.find_future_events
        events.should_not include(@started_before_and_ended_yesterday)
      end
    end

    describe "for date range" do
      it "should include ongoing events" do
        events = Event.find_by_dates(Time.now.beginning_of_day, Time.now+1.day, order = "start_time")
        events.should include(@started_midnight_and_continuing_after)
      end

      it "should not include past events" do
        events = Event.find_by_dates(Time.now.beginning_of_day, Time.now+1.day, order = "start_time")
        events.should_not include(@started_before_and_ended_yesterday)
      end

      # TODO figure out what this example was meant to do
      #it "should include events ongoing at the start of the range" do
      #  pending "should include events ongoing at the start of the range"
      #  events = Event.find_by_dates(@now - 1.days, @now + 1.days)
      #  events.should include(@started_before_and_continuing_after)
      #end
    end
  end

  describe "when searching" do
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

  describe "when associating with venues" do

    before(:each) do
      @venue = mock_model(Venue, :title => "MyVenue", :duplicate? => false)
    end

    it "should not change a venue to a nil venue" do
      @event.associate_with_venue(nil).should be_nil
    end

    it "should associate a venue if one wasn't set before" do
      @event.associate_with_venue(@venue).should == @venue
    end

    it "should change an existing venue to a different one" do
      @event.venue = mock_model(Venue, :title => "OtherVenue")

      @event.associate_with_venue(@venue).should == @venue
    end

    it "should not change a venue if associated with one of same name" do
      venue2 = mock_model(Venue, :title => "MyVenue")
      @event.venue = venue2

      @event.associate_with_venue(@venue).should == venue2
    end

    it "should clear an existing venue if given a nil venue" do
      @event.venue = @venue

      @event.associate_with_venue(nil).should be_nil
      @event.venue.should be_nil
    end

    it "should associate venue by title" do
      Venue.should_receive(:find_or_initialize_by_title).and_return(@venue)

      @event.associate_with_venue(@venue.title).should == @venue
    end

    it "should associate venue by id" do
      Venue.should_receive(:find).and_return(@venue)

      @event.associate_with_venue(1234).should == @venue
    end

    it "should raise an exception if associated with an unknown type" do
      lambda { @event.associate_with_venue(mock_model(SourceParser)) }.should raise_error(TypeError)
    end
  end
end
