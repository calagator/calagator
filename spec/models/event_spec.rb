require 'spec_helper'

describe Event do
  describe "in general"  do
    it "should be valid" do
      event = Event.new(:title => "Event title", :start_time => Time.zone.parse('2008.04.12'))
      event.should be_valid
    end

    it "should add a http:// prefix to urls without one" do
      event = Event.new(:title => "Event title", :start_time => Time.zone.parse('2008.04.12'), :url => 'google.com')
      event.should be_valid
    end
  end

  describe "when checking time status" do
    it "should be old if event ended before today" do
      Factory.build(:event, :start_time => today - 1.hour).should be_old
    end

    it "should be current if event is happening today" do
      Factory.build(:event, :start_time => today + 1.hour).should be_current
    end

    it "should be ongoing if it began before today but ends today or later" do
      Factory.build(:event, :start_time => today - 1.day, :end_time => today + 1.day).should be_ongoing
    end

    it "should be considered a multi-day event if it spans multiple days" do
      Factory.build(:event, :start_time => today - 1.day, :end_time => now + 1.day).should be_multiday
    end

    it "should be considered a multi-day event if it crosses a day boundry and is longer than the minimum duration (#{Event::MIN_MULTIDAY_DURATION.inspect})" do
      Event.new(:start_time => today - 1.second, :end_time => today + Event::MIN_MULTIDAY_DURATION).should be_multiday
    end

    it "should not be considered a multi-day event if it crosses a day boundry, but is not longer than the minimum duration (#{Event::MIN_MULTIDAY_DURATION.inspect})" do
      Event.new(:start_time => today - 1.second, :end_time => today - 1.second + Event::MIN_MULTIDAY_DURATION).should_not be_multiday
    end
  end

  describe "dealing with tags" do
    before do
      @tags = "some, tags"
      @event = Event.new(:title => "Tagging Day", :start_time => now)
    end

    it "should be taggable" do
      @event.tag_list.should eq []
    end

    it "should just cache tagging if it is a new record" do
      @event.should_not_receive :save
      @event.should_not_receive :tag_with
      @event.should be_new_record
      @event.tag_list = @tags
      @event.tag_list.to_s.should eq @tags
    end

    it "should use tags with punctuation" do
      tags = [".net", "foo-bar"]
      @event.tag_list = tags.join(", ")
      @event.save

      @event.reload
      @event.tags.map(&:name).sort.should eq tags.sort
    end

    it "should not interpret numeric tags as IDs" do
      tag = "123"
      @event.tag_list = tag
      @event.save

      @event.reload
      @event.tags.first.name.should eq "123"
    end

    it "should return a collection of events for a given tag" do
      @event.tag_list = @tags
      @event.save
      Event.tagged_with('tags').should eq [@event]
    end
  end

  describe "when parsing" do

    before do
      @basic_hcal = read_sample('hcal_basic.xml')
      @basic_venue = mock_model(Venue, :title => 'Argent Hotel, San Francisco, CA', :full_address => '50 3rd St, San Francisco, CA 94103')
      @basic_event = Event.new(
        :title => 'Web 2.0 Conference',
        :url => 'http://www.web2con.com/',
        :start_time => Time.zone.parse('2007-10-05'),
        :end_time => nil,
        :venue => @basic_venue)
    end

    it "should parse an AbstractEvent into an Event" do
      event = Event.new(:title => "EventTitle",
                        :description => "EventDescription",
                        :start_time => Time.zone.parse("2008-05-20"),
                        :end_time => Time.zone.parse("2008-05-22"))
      Event.should_receive(:new).and_return(event)

      abstract_event = SourceParser::AbstractEvent.new("EventTitle", "EventDescription", Time.zone.parse("2008-05-20"), Time.zone.parse("2008-05-22"))

      Event.from_abstract_event(abstract_event).should eq event
    end

    it "should parse an Event into an hCalendar" do
      actual_hcal = @basic_event.to_hcal
      pattern = Regexp.new(@basic_hcal.gsub(/\s+/, '\s+')) # Ignore spacing changes
      actual_hcal.should match pattern
    end

    it "should parse an Event into an iCalendar" do
      actual_ical = @basic_event.to_ical

      abstract_events = SourceParser.to_abstract_events(:content => actual_ical, :skip_old => false)

      abstract_events.size.should eq 1
      abstract_event = abstract_events.first
      abstract_event.title.should eq @basic_event.title
      abstract_event.url.should eq @basic_event.url
      abstract_event.description.should be_nil

      abstract_event.location.title.should match "#{@basic_event.venue.title}: #{@basic_event.venue.full_address}"
    end

    it "should parse an Event into an iCalendar without a URL and generate it" do
      generated_url = "http://foo.bar/"
      @basic_event.url = nil
      actual_ical = @basic_event.to_ical(:url_helper => lambda{|event| generated_url})

      abstract_events = SourceParser.to_abstract_events(:content => actual_ical, :skip_old => false)

      abstract_events.size.should eq 1
      abstract_event = abstract_events.first
      abstract_event.title.should eq @basic_event.title
      abstract_event.url.should eq @basic_event.url
      abstract_event.description.should match /Imported from: #{generated_url}/

      abstract_event.location.title.should match "#{@basic_event.venue.title}: #{@basic_event.venue.full_address}"
    end

  end

  describe "when finding duplicates" do
    it "should find all events with duplicate titles" do
      Event.should_receive(:find_by_sql).with("SELECT DISTINCT a.* from events a, events b WHERE a.id <> b.id AND ( a.title = b.title )")
      Event.find_duplicates_by(:title)
    end

    it "should find all events with duplicate titles and urls" do
      Event.should_receive(:find_by_sql).with("SELECT DISTINCT a.* from events a, events b WHERE a.id <> b.id AND ( a.title = b.title AND a.url = b.url )")
      Event.find_duplicates_by([:title,:url])
    end
  end

  describe "when finding duplicates by type" do
    def assert_default_find_duplicates_by_type(type)
      Event.should_receive(:future).and_return 42
      Event.find_duplicates_by_type(type).should eq({ [] => 42 })
    end

    it "should find all future events if called with nil" do
      assert_default_find_duplicates_by_type(nil)
    end

    it "should find all future events if called with empty string" do
      assert_default_find_duplicates_by_type('')
    end

    it "should find all future events if called with 'na'" do
      assert_default_find_duplicates_by_type('na')
    end

    def assert_specific_find_by_duplicates_by(type, queried)
      Event.should_receive(:find_duplicates_by).with(queried, {:grouped => true, :where => anything()})
      Event.find_duplicates_by_type(type)
    end

    it "should find events with all duplicate fields if called with 'all'" do
      assert_specific_find_by_duplicates_by('all', :all)
    end

    it "should find events with any duplicate fields if called with 'any'" do
      assert_specific_find_by_duplicates_by('any', :any)
    end

    it "should find events with duplicate titles if called with 'title'" do
      assert_specific_find_by_duplicates_by('title', ['title'])
    end
  end

  describe "when processing date" do
    before do
      @event = Event.new(:title => "MyEvent")
    end

    it "should fail to validate if start time is nil" do
      @event.start_time = nil
      @event.should_not be_valid
      @event.should have(1).error_on(:start_time)
    end

    it "should fail to validate if start time is blank" do
      @event.start_time = ""
      @event.should_not be_valid
      @event.should have(1).error_on(:start_time)
    end

    it "should fail to validate if end_time is earlier than start time " do
      @event.start_time = now
      @event.end_time = @event.start_time - 2.hours
      @event.save.should be_false
      @event.should have(1).error_on(:end_time)
    end

  end

  describe "#time_for" do
    before do
      @date = "2009-01-02"
      @time = "03:45"
      @date_time = "#{@date} #{@time}"
      @value = Time.zone.parse(@date_time)
    end

    it "should return nil for a NilClass" do
      Event.time_for(nil).should be_nil
    end

    it "should return time for a String" do
      Event.time_for(@date_time).should eq @value
    end

    it "should return time for an Array of Strings" do
      Event.time_for([@date, @time]).should eq @value
    end

    it "should return time for a DateTime" do
      Event.time_for(@value).should eq @value
    end

    it "should return exception for an invalid date expressed as a String" do
      lambda { Event.time_for("0/0/0") }.should raise_error
    end

    it "should raise exception for an invalid type" do
      lambda { Event.time_for(Event) }.should raise_error TypeError
    end
  end

  describe "#set_time_on" do
    it "should clear with nil" do
      Event.new(:start_time => nil).start_time.should be_nil
    end

    it "should set from date String" do
      event = Event.new(:start_time => today.to_date.to_s(:db))
      event.start_time.should be_a_kind_of Time
      event.start_time.should eq today
    end

    it "should set from date-time String" do
      event = Event.new(:start_time => today.localtime.to_s(:db))
      event.start_time.should be_a_kind_of Time
      event.start_time.should eq today
    end

    it "should set from Date" do
      event = Event.new(:start_time => today.to_date)
      event.start_time.should be_a_kind_of Time
      event.start_time.should eq today
    end

    it "should set from DateTime" do
      event = Event.new(:start_time => today.to_datetime)
      event.start_time.should be_a_kind_of Time
      event.start_time.should eq today
    end

    it "should set from TimeWithZone" do
      event = Event.new(:start_time => ActiveSupport::TimeWithZone.new(Time.now.midnight, Time.zone))
      event.start_time.should be_a_kind_of Time
      event.start_time.should eq today
    end

    it "should set from Time" do
      time = today
      event = Event.new(:start_time => time)
      event.start_time.should be_a_kind_of Time
      event.start_time.should eq time
    end

    it "should flag an invalid time" do
      event = Factory.build(:event)
      event.start_time = "1/0"
      event.errors[:start_time].should be_present
    end
  end

  describe "when finding by dates" do

    before do
      @today_midnight = today
      @yesterday = @today_midnight.yesterday
      @tomorrow = @today_midnight.tomorrow

      @this_venue = Venue.create!(:title => "This venue")

      @started_before_today_and_ends_after_today = Event.create!(
        :title => "Event in progress",
        :start_time => @yesterday,
        :end_time => @tomorrow,
        :venue_id => @this_venue.id)

      @started_midnight_and_continuing_after = Event.create!(
        :title => "Midnight start",
        :start_time => @today_midnight,
        :end_time => @tomorrow,
        :venue_id => @this_venue.id)

      @started_and_ended_yesterday = Event.create!(
        :title => "Yesterday start",
        :start_time => @yesterday,
        :end_time => @yesterday.end_of_day,
        :venue_id => @this_venue.id)

      @started_today_and_no_end_time = Event.create!(
        :title => "nil end time",
        :start_time => @today_midnight,
        :end_time => nil,
        :venue_id => @this_venue.id)

      @starts_and_ends_tomorrow = Event.create!(
        :title => "starts and ends tomorrow",
        :start_time => @tomorrow,
        :end_time => @tomorrow.end_of_day,
        :venue_id => @this_venue.id)

      @starts_after_tomorrow = Event.create!(
        :title => "Starting after tomorrow",
        :start_time => @tomorrow + 1.day,
        :venue_id => @this_venue.id)

      @started_before_today_and_ends_at_midnight = Event.create!(
        :title => "Midnight end",
        :start_time => @yesterday,
        :end_time => @today_midnight,
        :venue_id => @this_venue.id)

      @future_events_for_this_venue = @this_venue.events.future
    end

    describe "for overview" do
      # TODO:  consider writing the following specs as view specs
      # either in addition to, or instead of, model specs

      before do
        @overview = Event.select_for_overview
      end

      describe "events today" do
        it "should include events that started before today and end after today" do
          @overview[:today].should include @started_before_today_and_ends_after_today
        end

        it "should include events that started earlier today" do
          @overview[:today].should include @started_midnight_and_continuing_after
        end

        it "should not include events that ended before today" do
          @overview[:today].should_not include @started_and_ended_yesterday
        end

        it "should not include events that start tomorrow" do
          @overview[:today].should_not include @starts_and_ends_tomorrow
        end

        it "should not include events that ended at midnight today" do
          @overview[:today].should_not include @started_before_today_and_ends_at_midnight
        end
      end

      describe "events tomorrow" do
        it "should not include events that start after tomorrow" do
          @overview[:tomorrow].should_not include @starts_after_tomorrow
        end
      end

      describe "determining if we should show the more link" do
        it "should provide :more item if there are events past the future cutoff" do
          event = stub_model(Event)
          Event.should_receive(:first).with(:order=>"start_time asc", :conditions => ["start_time >= ?", today + 2.weeks]).and_return(event)

          Event.select_for_overview[:more].should eq event
        end

        it "should set :more item if there are no events past the future cutoff" do
          event = stub_model(Event)
          Event.should_receive(:first).with(:order=>"start_time asc", :conditions => ["start_time >= ?", today + 2.weeks]).and_return(event)

          Event.select_for_overview[:more?].should be_blank
        end
      end
    end

    describe "for future events" do
      before do
        @future_events = Event.future
      end

      it "should include events that started earlier today" do
        @future_events.should include @started_midnight_and_continuing_after
      end

      it "should include events with no end time that started today" do
        @future_events.should include @started_today_and_no_end_time
      end

      it "should include events that started before today and ended after today" do
        events = Event.future
        events.should include @started_before_today_and_ends_after_today
      end

      it "should include events with no end time that started today" do
        @future_events.should include @started_today_and_no_end_time
      end

      it "should not include events that ended before today" do
        @future_events.should_not include @started_and_ended_yesterday
      end
    end

    describe "for future events with venue" do
      before do
        @another_venue = Venue.create!(:title => "Another venue")

        @future_event_another_venue = Event.create!(
          :title => "Starting after tomorrow",
          :start_time => @tomorrow + 1.day,
          :venue_id => @another_venue.id)

        @future_event_no_venue = Event.create!(
          :title => "Starting after tomorrow",
          :start_time => @tomorrow + 1.day)
      end

      # TODO Consider moving these examples elsewhere because they don't appear to relate to this scope. This comment applies to the examples from here...
      it "should include events that started earlier today" do
        @future_events_for_this_venue.should include @started_midnight_and_continuing_after
      end

      it "should include events with no end time that started today" do
        @future_events_for_this_venue.should include @started_today_and_no_end_time
      end

      it "should include events that started before today and ended after today" do
        @future_events_for_this_venue.should include @started_before_today_and_ends_after_today
      end

      it "should not include events that ended before today" do
        @future_events_for_this_venue.should_not include @started_and_ended_yesterday
      end
      # TODO ...to here.

      it "should not include events for another venue" do
        @future_events_for_this_venue.should_not include @future_event_another_venue
      end

      it "should not include events with no venue" do
        @future_events_for_this_venue.should_not include @future_event_no_venue
      end
    end

    describe "for date range" do
      it "should include events that started earlier today" do
        events = Event.within_dates(@today_midnight, @tomorrow)
        events.should include @started_midnight_and_continuing_after
      end

      it "should include events that started before today and end after today" do
        events = Event.within_dates(@today_midnight, @tomorrow)
        events.should include @started_before_today_and_ends_after_today
      end

      it "should not include past events" do
        events = Event.within_dates(@today_midnight, @tomorrow)
        events.should_not include @started_and_ended_yesterday
      end

      it "should exclude events that start after the end of the range" do
        events = Event.within_dates(@tomorrow, @tomorrow)
        events.should_not include @started_today_and_no_end_time
      end
    end
  end

  describe "when searching" do
    it "should find events" do
      Event.should_receive(:search).and_return([])

      Event.search("myquery").should be_empty
    end

    it "should find events and group them" do
      current_event = mock_model(Event, :current? => true, :duplicate_of_id => nil)
      past_event = mock_model(Event, :current? => false, :duplicate_of_id => nil)
      Event.should_receive(:search).and_return([current_event, past_event])

      Event.search_keywords_grouped_by_currentness("myquery").should eq({
        :current => [current_event],
        :past    => [past_event],
      })
    end

    it "should find events" do
      event_Z = Event.new(:title => "Zipadeedoodah", :start_time => (now + 1.week))
      event_A = Event.new(:title => "Antidisestablishmentarism", :start_time => (now + 2.weeks))
      event_O = Event.new(:title => "Ooooooo! Oooooooooooooo!", :start_time => (now + 3.weeks))
      event_o = Event.new(:title => "ommmmmmmmmmm...", :start_time => (now + 4.weeks))

      Event.should_receive(:search).and_return([event_A, event_Z, event_O, event_o])

      Event.search_keywords_grouped_by_currentness("myquery", :order => 'name').should eq({
        :current => [event_A, event_Z, event_O, event_o],
        :past => []
      })
    end
  end

  describe "when associating with venues" do
    before do
      @event = Factory(:event)
      @venue = Factory(:venue)
    end

    it "should not change a venue to a nil venue" do
      @event.associate_with_venue(nil).should be_nil
    end

    it "should associate a venue if one wasn't set before" do
      @event.associate_with_venue(@venue).should eq @venue
    end

    it "should change an existing venue to a different one" do
      @event.venue = Factory(:venue, :duplicate_of => @venue)

      @event.associate_with_venue(@venue).should eq @venue
    end

    it "should clear an existing venue if given a nil venue" do
      @event.venue = @venue

      @event.associate_with_venue(nil).should be_nil
      @event.venue.should be_nil
    end

    it "should associate venue by title" do
      Venue.should_receive(:find_or_initialize_by_title).and_return(@venue)

      @event.associate_with_venue(@venue.title).should eq @venue
    end

    it "should associate venue by id" do
      @event.associate_with_venue(@venue.id).should eq @venue
    end

    it "should raise an exception if there's a loop in the duplicates chain" do
      venue1 = Factory(:venue)
      venue2 = Factory(:venue, :duplicate_of => venue1)
      venue1.update_attribute(:duplicate_of, venue2)

      lambda { @event.associate_with_venue(venue1.id) }.should raise_error DuplicateCheckingError
    end

    it "should raise an exception if associated with an unknown type" do
      lambda { @event.associate_with_venue(double('SourceParser')) }.should raise_error TypeError
    end

    describe "and searching" do
      it "should find events" do
        event_A = Event.new(:title => "Zipadeedoodah", :start_time => (now + 1.week))
        event_o = Event.new(:title => "Antidisestablishmentarism", :start_time => (now + 2.weeks))
        event_O = Event.new(:title => "Ooooooo! Oooooooooooooo!", :start_time => (now + 3.weeks))
        event_Z = Event.new(:title => "ommmmmmmmmmm...", :start_time => (now + 4.weeks))

        event_A.venue = Venue.new(:title => "Acme Hotel")
        event_o.venue = Venue.new(:title => "opbmusic Studios")
        event_O.venue = Venue.new(:title => "Oz")
        event_Z.venue = Venue.new(:title => "Zippers and Things")

        Event.should_receive(:search).and_return([event_A, event_Z, event_O, event_o])

        Event.search_keywords_grouped_by_currentness("myquery", :order => 'venue').should eq({
          :current => [event_A, event_Z, event_O, event_o],
          :past => []
        })
      end
    end
  end

  describe "with finding duplicates" do
    it "should find all events with duplicate titles" do
      Event.should_receive(:find_by_sql).with("SELECT DISTINCT a.* from events a, events b WHERE a.id <> b.id AND ( a.title = b.title )")
      Event.find_duplicates_by(:title )
    end

    it "should find all events with duplicate titles and urls" do
      Event.should_receive(:find_by_sql).with("SELECT DISTINCT a.* from events a, events b WHERE a.id <> b.id AND ( a.title = b.title AND a.url = b.url )")
      Event.find_duplicates_by([:title,:url])
    end

    describe "with sample records" do
      before do
        @non_duplicate_event = Factory(:event)
        @duplicate_event = Factory(:duplicate_event)
        @events = [@non_duplicate_event, @duplicate_event]
      end

      it "should find all events that have not been marked as duplicate" do
        non_duplicates = Event.non_duplicates
        non_duplicates.should include @non_duplicate_event
        non_duplicates.should_not include @duplicate_event
      end

      it "should find all events that have been marked as duplicate" do
        duplicates = Event.marked_duplicates
        duplicates.should include @duplicate_event
        duplicates.should_not include @non_duplicate_event
      end
    end
  end

  describe "with finding duplicates (integration test)" do
    before do
      @event = Factory(:event)
    end

    # Find duplicates, create another event with the given attributes, and find duplicates again
    # TODO Refactor #find_duplicates_create_a_clone_and_find_again and its uses into something simpler, like #assert_duplicate_count.
    def find_duplicates_create_a_clone_and_find_again(find_duplicates_arguments, clone_attributes, create_class = Event)
      before_results = create_class.find_duplicates_by( find_duplicates_arguments)
      clone = create_class.create!(clone_attributes)
      after_results = Event.find_duplicates_by(find_duplicates_arguments)
      return [before_results.sort_by(&:created_at), after_results.sort_by(&:created_at)]
    end

    it "should find duplicate title by title" do
      pre, post = find_duplicates_create_a_clone_and_find_again(:title, {:title => @event.title, :start_time => @event.start_time} )
      post.size.should eq(pre.size + 2)
    end

    it "should find duplicate title by any" do
      # TODO figure out why the #find_duplicates_create_a_clone_and_find_again isn't giving expected results and a workaround was needed.
      #pre, post = find_duplicates_create_a_clone_and_find_again(:any, {:title => @event.title, :start_time => @event.start_time} )
      #post.size.should eq(pre.size + 2)
      dup_title = Event.create!({:title => @event.title, :start_time => @event.start_time + 1.minute})
      Event.find_duplicates_by(:any).should include dup_title
    end

    it "should not find duplicate title by url" do
      pre, post = find_duplicates_create_a_clone_and_find_again(:url, {:title => @event.title, :start_time => @event.start_time} )
      post.size.should eq pre.size
    end

    it "should find complete duplicates by all" do
      pre, post = find_duplicates_create_a_clone_and_find_again(:all, @event.attributes)
      post.size.should eq(pre.size + 2)
    end

    it "should not find incomplete duplicates by all" do
      pre, post = find_duplicates_create_a_clone_and_find_again(:all, @event.attributes.merge(:title => "SpaceCube", :start_time => @event.start_time ))
      post.size.should eq pre.size
    end

    it "should find duplicate for matching multiple fields" do
      pre, post = find_duplicates_create_a_clone_and_find_again([:title, :start_time], {:title => @event.title, :start_time => @event.start_time })
      post.size.should eq(pre.size + 2)
    end

    it "should not find duplicates for mismatching multiple fields" do
      pre, post = find_duplicates_create_a_clone_and_find_again([:title, :start_time], {:title => "SpaceCube", :start_time => @event.start_time })
      post.size.should eq pre.size
    end
  end

  describe "when squashing duplicates (integration test)" do
    before do
      @event = Factory(:event)
    end

    it "should consolidate associations, and merge tags" do
      @event.tag_list = %w[first second] # master event contains one duplicate tag, and one unique tag

      clone = Event.create!(@event.attributes)
      clone.tag_list.replace %w[second third] # duplicate event also contains one duplicate tag, and one unique tag
      clone.save!
      clone.reload
      clone.should_not be_duplicate

      Event.squash(:master => @event, :duplicates => clone)
      @event.tag_list.to_a.sort.should eq %w[first second third] # master now contains all three tags
      clone.duplicate_of.should eq @event
    end
  end

  describe "when checking for squashing" do
    before do
      @today  = today
      @master = Event.create!(:title => "Master",    :start_time => @today)
      @slave1 = Event.create!(:title => "1st slave", :start_time => @today, :duplicate_of_id => @master.id)
      @slave2 = Event.create!(:title => "2nd slave", :start_time => @today, :duplicate_of_id => @slave1.id)
      @orphan = Event.create!(:title => "orphan",    :start_time => @today, :duplicate_of_id => 999999)
    end

    it "should recognize a master" do
      @master.should be_a_master
    end

    it "should recognize a slave" do
      @slave1.should be_a_slave
    end

    it "should not think that a slave is a master" do
      @slave2.should_not be_a_master
    end

    it "should not think that a master is a slave" do
      @master.should_not be_a_slave
    end

    it "should return the progenitor of a child" do
      @slave1.progenitor.should eq @master
    end

    it "should return the progenitor of a grandchild" do
      @slave2.progenitor.should eq @master
    end

    it "should return a master as its own progenitor" do
      @master.progenitor.should eq @master
    end

    it "should return a marked duplicate as progenitor if it is orphaned"  do
      @orphan.progenitor.should eq @orphan
    end

    it "should return the progenitor if an imported event has an exact duplicate" do
      @abstract_event = SourceParser::AbstractEvent.new
      @abstract_event.title = @slave2.title
      @abstract_event.start_time = @slave2.start_time.to_s

      Event.from_abstract_event(@abstract_event).should eq @master
    end

  end

  describe "when versioning" do
    it "should have versions" do
      Event.new.versions.should eq []
    end

    it "should create a new version after updating" do
      event = Event.create!(:title => "Event title", :start_time => Time.zone.parse('2008.04.12'))
      event.versions.count.should eq 1

      event.title = "New Title"
      event.save!
      event.versions.count.should eq 2
    end
  end

  describe "when normalizing line-endings in the description" do
    before do
      @event = Event.new
    end

    it "should not molest contents without carriage-returns" do
      @event.description         = "foo\nbar"
      @event.description.should eq "foo\nbar"
    end

    it "should replace CRLF with LF" do
      @event.description         = "foo\r\nbar"
      @event.description.should eq "foo\nbar"
    end

    it "should replace stand-alone CR with LF" do
      @event.description         = "foo\rbar"
      @event.description.should eq "foo\nbar"
    end
  end

  describe "when cloning" do
    let :original do
      Factory.build(:event,
        :id => 42,
        :start_time => Time.parse("2008-01-19 10:00 PST"),
        :end_time => Time.parse("2008-01-19 17:00 PST"),
        :tag_list => "foo, bar, baz",
        :venue_details => "Details")
    end

    subject do
      original.to_clone
    end

    its(:new_record?) { should be_true }

    its(:id) { should be_nil }

    its(:start_time) { should eq today + original.start_time.hour.hours }

    its(:end_time)   { should eq today + original.end_time.hour.hours }

    its(:tag_list) { should eq original.tag_list }

    %w[title description url venue_id venue_details].each do |field|
      its(field) { should eq original[field] }
    end
  end

  describe "when converting to iCal" do
    def ical_roundtrip(events, opts = {})
      parsed_events = RiCal.parse_string(Event.to_ical(events, opts)).first.events
      if events.is_a?(Event)
        parsed_events.first
      else
        parsed_events
      end
    end

    it "should produce parsable iCal output" do
      lambda { ical_roundtrip( Factory.build(:event) ) }.should_not raise_error
    end

    it "should represent an event without an end time as a 1-hour block" do
      event = Factory.build(:event, :start_time => now, :end_time => nil)
      event.end_time.should be_blank

      rt = ical_roundtrip(event)
      (rt.dtend - rt.dtstart).should eq 1.hour
    end

    it "should set the appropriate end time if one is given" do
      event = Factory.build(:event, :start_time => now, :end_time => now + 2.hours)

      rt = ical_roundtrip(event)
      (rt.dtend - rt.dtstart).should eq 2.hours
    end

    describe "when comparing Event's attributes to its iCalendar output" do
      let(:event) { Factory.build(:event, :id => 123, :created_at => now) }
      let(:ical) { ical_roundtrip(event) }

      { :summary => :title,
        :created => :created_at,
        :last_modified => :updated_at,
        :description => :description,
        :url => :url,
        :dtstart => :start_time,
        :dtstamp => :created_at
      }.each do |ical_attribute, model_attribute|
        it "should map the Event's #{model_attribute} attribute to '#{ical_attribute}' in the iCalendar output" do
          model_value = event.send(model_attribute)
          ical_value = ical.send(ical_attribute)

          case model_value
          when ActiveSupport::TimeWithZone
            # Compare raw time because one is using local time zone, while other is using UTC time.
            model_value.to_i.should eq ical_value.to_i
          else
            model_value.should eq ical_value
          end
        end
      end
    end

    it "should call the URL helper to generate a UID" do
      event = Factory.build(:event)
      ical_roundtrip(event, :url_helper => lambda {|e| "UID'D!" }).uid.should eq "UID'D!"
    end

    it "should strip HTML from the description" do
      event = Factory(:event, :description => "<blink>OMFG HTML IS TEH AWESOME</blink>")
      ical_roundtrip(event).description.should_not include "<blink>"
    end

    it "should include tags in the description" do
      event = Factory.build(:event)
      event.tag_list = "tags, folksonomy, categorization"
      ical_roundtrip(event).description.should include event.tag_list.to_s
    end

    it "should leave URL blank if no URL is provided" do
      event = Factory.build(:event, :url => nil)
      ical_roundtrip(event).url.should be_nil
    end

    it "should have Source URL if URL helper is given)" do
      event = Factory.build(:event)
      ical_roundtrip(event, :url_helper => lambda{|e| "FAKE"} ).description.should match /FAKE/
    end

    it "should create multi-day entries for multi-day events" do
      time = Time.now
      event = Factory.build(:event, :start_time => time, :end_time => time + 4.days)
      parsed_event = ical_roundtrip( event )

      start_time = Date.today
      parsed_event.dtstart.should eq start_time
      parsed_event.dtend.should eq(start_time + 5.days)
    end

    describe "sequence" do
      def event_to_ical(event)
        return RiCal.parse_string(Event.to_ical([event])).first.events.first
      end

      it "should set an initial sequence on a new event" do
        event = Factory(:event)
        ical = event_to_ical(event)
        ical.sequence.should eq 1
      end

      it "should increment the sequence if it is updated" do
        event = Factory(:event)
        event.update_attribute(:title, "Update 1")
        ical = event_to_ical(event)
        ical.sequence.should eq 2
      end

      # it "should offset the squence based the global SECRETS.icalendar_sequence_offset" do
        # SECRETS.should_receive(:icalendar_sequence_offset).and_return(41)
        # event = Factory.build(:event)
        # ical = event_to_ical(event)
        # ical.sequence.should eq 42
      # end
    end

    describe "- the headers" do
      before do
        @data = Factory.build(:event).to_ical
      end

      it "should include the calendar name" do
        @data.should match /\sX-WR-CALNAME:#{SETTINGS.name}\s/
      end

      it "should include the method" do
        @data.should match /\sMETHOD:PUBLISH\s/
      end

      it "should include the scale" do
        @data.should match /\sCALSCALE:Gregorian\s/i
      end
    end

  end

  describe "sorting labels" do
    it "should have sorting labels" do
      Event::SORTING_LABELS.should be_a_kind_of Hash
    end

    it "should display human-friendly label for a known value" do
      Event::sorting_label_for('name').should eq 'Event Name'
    end

    it "should display a default label" do
      Event::sorting_label_for(nil).should eq 'Relevance'
    end

    it "should display a different default label when searching by tag" do
      Event::sorting_label_for(nil, true).should eq 'Date'
    end
  end

end
