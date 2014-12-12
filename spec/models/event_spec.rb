require 'spec_helper'

describe Event, :type => :model do
  describe "in general"  do
    it "should be valid" do
      event = Event.new(:title => "Event title", :start_time => Time.zone.parse('2008.04.12'))
      expect(event).to be_valid
    end

    it "should add a http:// prefix to urls without one" do
      event = Event.new(:title => "Event title", :start_time => Time.zone.parse('2008.04.12'), :url => 'google.com')
      expect(event).to be_valid
    end

    it "validates blacklisted words" do
      event = Event.new(:title => "Foo bar cialis", :start_time => Time.zone.parse('2008.04.12'), :url => 'google.com')
      expect(event).not_to be_valid
    end
  end

  describe "when checking time status" do
    it "should be old if event ended before today" do
      expect(FactoryGirl.build(:event, :start_time => today - 1.hour)).to be_old
    end

    it "should be current if event is happening today" do
      expect(FactoryGirl.build(:event, :start_time => today + 1.hour)).to be_current
    end

    it "should be ongoing if it began before today but ends today or later" do
      expect(FactoryGirl.build(:event, :start_time => today - 1.day, :end_time => today + 1.day)).to be_ongoing
    end
  end

  describe "dealing with tags" do
    before do
      @tags = "some, tags"
      @event = Event.new(:title => "Tagging Day", :start_time => now)
    end

    it "should be taggable" do
      expect(@event.tag_list).to eq []
    end

    it "should just cache tagging if it is a new record" do
      expect(@event).not_to receive :save
      expect(@event).to be_new_record
      @event.tag_list = @tags
      expect(@event.tag_list.to_s).to eq @tags
    end

    it "should use tags with punctuation" do
      tags = [".net", "foo-bar"]
      @event.tag_list = tags.join(", ")
      @event.save

      @event.reload
      expect(@event.tags.map(&:name).sort).to eq tags.sort
    end

    it "should not interpret numeric tags as IDs" do
      tag = "123"
      @event.tag_list = tag
      @event.save

      @event.reload
      expect(@event.tags.first.name).to eq "123"
    end

    it "should return a collection of events for a given tag" do
      @event.tag_list = @tags
      @event.save
      expect(Event.tagged_with('tags')).to eq [@event]
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

    it "should parse an iCalendar into an Event" do
      url = "http://foo.bar/"
      actual_ical = Event::IcalRenderer.render(@basic_event)
      stub_request(:get, url).to_return(body: actual_ical)

      events = Source::Parser.to_events(url: url, skip_old: false)

      expect(events.size).to eq 1
      event = events.first
      expect(event.title).to eq @basic_event.title
      expect(event.url).to eq @basic_event.url
      expect(event.description).to be_blank

      expect(event.venue.title).to match "#{@basic_event.venue.title}: #{@basic_event.venue.full_address}"
    end

    it "should parse an iCalendar into an Event without a URL and generate it" do
      generated_url = "http://foo.bar/"
      @basic_event.url = nil
      actual_ical = Event::IcalRenderer.render(@basic_event, :url_helper => lambda{|event| generated_url})
      url = "http://foo.bar/"
      stub_request(:get, url).to_return(body: actual_ical)

      events = Source::Parser.to_events(url: url, skip_old: false)

      expect(events.size).to eq 1
      event = events.first
      expect(event.title).to eq @basic_event.title
      expect(event.url).to eq @basic_event.url
      expect(event.description).to match /Imported from: #{generated_url}/

      expect(event.venue.title).to match "#{@basic_event.venue.title}: #{@basic_event.venue.full_address}"
    end
  end

  describe "when finding duplicates by type" do
    def assert_default_find_duplicates_by_type(type)
      expect(Event).to receive(:future).and_return 42
      expect(Event.find_duplicates_by_type(type)).to eq({ [] => 42 })
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
      expect(Event).to receive(:find_duplicates_by).with(queried, {:grouped => true, :where => anything()})
      Event.find_duplicates_by_type(type)
    end

    it "should find events with all duplicate fields if called with 'all'" do
      assert_specific_find_by_duplicates_by('all', :all)
    end

    it "should find events with any duplicate fields if called with 'any'" do
      assert_specific_find_by_duplicates_by('any', :any)
    end

    it "should find events with duplicate titles if called with 'title'" do
      assert_specific_find_by_duplicates_by('title', [:title])
    end
  end

  describe "when processing date" do
    before do
      @event = Event.new(:title => "MyEvent")
    end

    it "should fail to validate if start time is nil" do
      @event.start_time = nil
      expect(@event).not_to be_valid
      expect(@event.errors[:start_time].size).to eq(1)
    end

    it "should fail to validate if start time is blank" do
      @event.start_time = ""
      expect(@event).not_to be_valid
      expect(@event.errors[:start_time].size).to eq(1)
    end

    it "should fail to validate if end_time is earlier than start time " do
      @event.start_time = now
      @event.end_time = @event.start_time - 2.hours
      expect(@event).to be_invalid
      expect(@event.errors[:end_time].size).to eq(1)
    end
  end

  describe "when processing url" do
    before do
      @event = Event.new(:title => 'MyEvent', :start_time => now)
    end

    let(:valid_urls) {[
      "hackoregon.org",
      "http://www.meetup.com/Hack_Oregon-Data/events/",
      "example.com",
      "sub.example.com/",
      "sub.domain.my-example.com",
      "example.com/?stuff=true",
      "example.com:5000/?stuff=true",
      "sub.domain.my-example.com/path/to/file/hello.html",
      "hello.museum",
      "http://example.com",
    ]}

    let(:invalid_urls){[
      "hackoregon.org, http://www.meetup.com/Hack_Oregon-Data/events/",
      "hackoregon.org\nhttp://www.meetup.com/",
      "htttp://www.example.com"
    ]}

    it "should validate with valid urls (with scheme included or not)" do
      valid_urls.each do |valid_url|
        @event.url = valid_url
        expect(@event).to be_valid
      end
    end

    it "should fail to validate with invalid urls (with scheme included or not)" do
      invalid_urls.each do |invalid_url|
        @event.url = invalid_url
        expect(@event).to be_invalid
      end
    end
  end

  describe "#start_time=" do
    it "should clear with nil" do
      expect(Event.new(:start_time => nil).start_time).to be_nil
    end

    it "should set from date String" do
      event = Event.new(:start_time => "2009-01-02")
      expect(event.start_time).to eq Time.zone.parse("2009-01-02")
    end

    it "should set from date-time String" do
      event = Event.new(:start_time => "2009-01-02 03:45")
      expect(event.start_time).to eq Time.zone.parse("2009-01-02 03:45")
    end

    it "should set from an Array of Strings" do
      event = Event.new(:start_time => ["2009-01-03", "02:14"])
      expect(event.start_time).to eq Time.zone.parse("2009-01-03 02:14")
    end

    it "should set from Date" do
      event = Event.new(:start_time => Date.parse("2009-02-01"))
      expect(event.start_time).to eq Time.zone.parse("2009-02-01")
    end

    it "should set from DateTime" do
      event = Event.new(:start_time => Time.zone.parse("2009-01-01 05:30"))
      expect(event.start_time).to eq Time.zone.parse("2009-01-01 05:30")
    end

    it "should flag an invalid time and reset to nil" do
      event = Event.new(:start_time => "2010/1/1")
      event.start_time = "1/0"
      expect(event.start_time).to be_nil
      expect(event.errors[:start_time]).to be_present
    end
  end

  describe "#end_time=" do
    it "should clear with nil" do
      expect(Event.new(:end_time => nil).end_time).to be_nil
    end

    it "should set from date String" do
      event = Event.new(:end_time => "2009-01-02")
      expect(event.end_time).to eq Time.zone.parse("2009-01-02")
    end

    it "should set from date-time String" do
      event = Event.new(:end_time => "2009-01-02 03:45")
      expect(event.end_time).to eq Time.zone.parse("2009-01-02 03:45")
    end

    it "should set from an Array of Strings" do
      event = Event.new(:end_time => ["2009-01-03", "02:14"])
      expect(event.end_time).to eq Time.zone.parse("2009-01-03 02:14")
    end

    it "should set from Date" do
      event = Event.new(:end_time => Date.parse("2009-02-01"))
      expect(event.end_time).to eq Time.zone.parse("2009-02-01")
    end

    it "should set from DateTime" do
      event = Event.new(:end_time => Time.zone.parse("2009-01-01 05:30"))
      expect(event.end_time).to eq Time.zone.parse("2009-01-01 05:30")
    end

    it "should flag an invalid time" do
      event = Event.new(:end_time => "1/0")
      expect(event.errors[:end_time]).to be_present
    end
  end

  describe "#dates" do
    it "returns an array of dates spanned by the event" do
      event = Event.new(start_time: "2010-01-01", end_time: "2010-01-03")
      expect(event.dates).to eq([
        Date.parse("2010-01-01"),
        Date.parse("2010-01-02"),
        Date.parse("2010-01-03"),
      ])
    end

    it "returns an array of one date when there is no end time" do
      event = Event.new(start_time: "2010-01-01")
      expect(event.dates).to eq([Date.parse("2010-01-01")])
    end

    it "throws ArgumentError when there is no start time" do
      expect { Event.new.dates }.to raise_error(ArgumentError)
    end
  end

  describe "#duration" do
    it "returns the event length in seconds" do
      event = Event.new(start_time: "2010-01-01", end_time: "2010-01-03")
      expect(event.duration).to eq(172800)
    end

    it "returns zero if start and end times aren't present" do
      expect(Event.new.duration).to eq(0)
    end
  end

  describe "#location" do
    it "delegates to the venue's location" do
      event = Event.new
      event.build_venue latitude: 45.5200, longitude: 122.6819
      expect(event.location).to eq([45.5200, 122.6819])
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

    describe "for future events" do
      before do
        @future_events = Event.future
      end

      it "should include events that started earlier today" do
        expect(@future_events).to include @started_midnight_and_continuing_after
      end

      it "should include events with no end time that started today" do
        expect(@future_events).to include @started_today_and_no_end_time
      end

      it "should include events that started before today and ended after today" do
        events = Event.future
        expect(events).to include @started_before_today_and_ends_after_today
      end

      it "should include events with no end time that started today" do
        expect(@future_events).to include @started_today_and_no_end_time
      end

      it "should not include events that ended before today" do
        expect(@future_events).not_to include @started_and_ended_yesterday
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
        expect(@future_events_for_this_venue).to include @started_midnight_and_continuing_after
      end

      it "should include events with no end time that started today" do
        expect(@future_events_for_this_venue).to include @started_today_and_no_end_time
      end

      it "should include events that started before today and ended after today" do
        expect(@future_events_for_this_venue).to include @started_before_today_and_ends_after_today
      end

      it "should not include events that ended before today" do
        expect(@future_events_for_this_venue).not_to include @started_and_ended_yesterday
      end
      # TODO ...to here.

      it "should not include events for another venue" do
        expect(@future_events_for_this_venue).not_to include @future_event_another_venue
      end

      it "should not include events with no venue" do
        expect(@future_events_for_this_venue).not_to include @future_event_no_venue
      end
    end

    describe "for date range" do
      it "should include events that started earlier today" do
        events = Event.within_dates(@today_midnight, @tomorrow)
        expect(events).to include @started_midnight_and_continuing_after
      end

      it "should include events that started before today and end after today" do
        events = Event.within_dates(@today_midnight, @tomorrow)
        expect(events).to include @started_before_today_and_ends_after_today
      end

      it "should not include past events" do
        events = Event.within_dates(@today_midnight, @tomorrow)
        expect(events).not_to include @started_and_ended_yesterday
      end

      it "should exclude events that start after the end of the range" do
        events = Event.within_dates(@tomorrow, @tomorrow)
        expect(events).not_to include @started_today_and_no_end_time
      end
    end
  end

  describe "when ordering" do
    describe "with .ordered_by_ui_field" do
      it "defaults to order by start time" do
        event1 = FactoryGirl.create(:event, start_time: Date.parse("2003-01-01"))
        event2 = FactoryGirl.create(:event, start_time: Date.parse("2002-01-01"))
        event3 = FactoryGirl.create(:event, start_time: Date.parse("2001-01-01"))

        events = Event.ordered_by_ui_field(nil)
        expect(events).to eq([event3, event2, event1])
      end

      it "can order by event name" do
        event1 = FactoryGirl.create(:event, title: "CU there")
        event2 = FactoryGirl.create(:event, title: "Be there")
        event3 = FactoryGirl.create(:event, title: "An event")

        events = Event.ordered_by_ui_field("name")
        expect(events).to eq([event3, event2, event1])
      end

      it "can order by venue name" do
        event1 = FactoryGirl.create(:event, venue: FactoryGirl.create(:venue, title: "C venue"))
        event2 = FactoryGirl.create(:event, venue: FactoryGirl.create(:venue, title: "B venue"))
        event3 = FactoryGirl.create(:event, venue: FactoryGirl.create(:venue, title: "A venue"))

        events = Event.ordered_by_ui_field("venue")
        expect(events).to eq([event3, event2, event1])
      end
    end
  end

  describe "with finding duplicates" do
    before do
      @non_duplicate_event = FactoryGirl.create(:event)
      @duplicate_event = FactoryGirl.create(:duplicate_event)
      @events = [@non_duplicate_event, @duplicate_event]
    end

    it "should find all events that have not been marked as duplicate" do
      non_duplicates = Event.non_duplicates
      expect(non_duplicates).to include @non_duplicate_event
      expect(non_duplicates).not_to include @duplicate_event
    end

    it "should find all events that have been marked as duplicate" do
      duplicates = Event.marked_duplicates
      expect(duplicates).to include @duplicate_event
      expect(duplicates).not_to include @non_duplicate_event
    end
  end

  describe "with finding duplicates (integration test)" do
    before do
      @event = FactoryGirl.create(:event)
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
      expect(post.size).to eq(pre.size + 2)
    end

    it "should find duplicate title by any" do
      # TODO figure out why the #find_duplicates_create_a_clone_and_find_again isn't giving expected results and a workaround was needed.
      #pre, post = find_duplicates_create_a_clone_and_find_again(:any, {:title => @event.title, :start_time => @event.start_time} )
      #post.size.should eq(pre.size + 2)
      dup_title = Event.create!({:title => @event.title, :start_time => @event.start_time + 1.minute})
      expect(Event.find_duplicates_by(:any)).to include dup_title
    end

    it "should not find duplicate title by url" do
      pre, post = find_duplicates_create_a_clone_and_find_again(:url, {:title => @event.title, :start_time => @event.start_time} )
      expect(post.size).to eq pre.size
    end

    it "should find complete duplicates by all" do
      pre, post = find_duplicates_create_a_clone_and_find_again(:all, @event.attributes)
      expect(post.size).to eq(pre.size + 2)
    end

    it "should not find incomplete duplicates by all" do
      pre, post = find_duplicates_create_a_clone_and_find_again(:all, @event.attributes.merge(:title => "SpaceCube", :start_time => @event.start_time ))
      expect(post.size).to eq pre.size
    end

    it "should find duplicate for matching multiple fields" do
      pre, post = find_duplicates_create_a_clone_and_find_again([:title, :start_time], {:title => @event.title, :start_time => @event.start_time })
      expect(post.size).to eq(pre.size + 2)
    end

    it "should not find duplicates for mismatching multiple fields" do
      pre, post = find_duplicates_create_a_clone_and_find_again([:title, :start_time], {:title => "SpaceCube", :start_time => @event.start_time })
      expect(post.size).to eq pre.size
    end
  end

  describe "when squashing duplicates (integration test)" do
    before do
      @event = FactoryGirl.create(:event)
    end

    it "should consolidate associations, and merge tags" do
      @event.tag_list = %w[first second] # master event contains one duplicate tag, and one unique tag

      clone = Event.create!(@event.attributes)
      clone.tag_list.replace %w[second third] # duplicate event also contains one duplicate tag, and one unique tag
      clone.save!
      clone.reload
      expect(clone).not_to be_duplicate

      Event.squash(@event, clone)
      expect(@event.tag_list.to_a.sort).to eq %w[first second third] # master now contains all three tags
      expect(clone.duplicate_of).to eq @event
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
      expect(@master).to be_a_master
    end

    it "should recognize a slave" do
      expect(@slave1).to be_a_slave
    end

    it "should not think that a slave is a master" do
      expect(@slave2).not_to be_a_master
    end

    it "should not think that a master is a slave" do
      expect(@master).not_to be_a_slave
    end

    it "should return the progenitor of a child" do
      expect(@slave1.progenitor).to eq @master
    end

    it "should return the progenitor of a grandchild" do
      expect(@slave2.progenitor).to eq @master
    end

    it "should return a master as its own progenitor" do
      expect(@master.progenitor).to eq @master
    end

    it "should return a marked duplicate as progenitor if it is orphaned"  do
      expect(@orphan.progenitor).to eq @orphan
    end
  end

  describe "when versioning" do
    it "should have versions" do
      expect(Event.new.versions).to eq []
    end

    it "should create a new version after updating" do
      event = Event.create!(:title => "Event title", :start_time => Time.zone.parse('2008.04.12'))
      expect(event.versions.count).to eq 1

      event.title = "New Title"
      event.save!
      expect(event.versions.count).to eq 2
    end
  end

  describe "when normalizing line-endings in the description" do
    before do
      @event = Event.new
    end

    it "should not molest contents without carriage-returns" do
      @event.description         = "foo\nbar"
      expect(@event.description).to eq "foo\nbar"
    end

    it "should replace CRLF with LF" do
      @event.description         = "foo\r\nbar"
      expect(@event.description).to eq "foo\nbar"
    end

    it "should replace stand-alone CR with LF" do
      @event.description         = "foo\rbar"
      expect(@event.description).to eq "foo\nbar"
    end
  end

  describe "when converting to iCal" do
    def ical_roundtrip(events, opts = {})
      parsed_events = RiCal.parse_string(Event::IcalRenderer.render(events, opts)).first.events
      if events.is_a?(Event)
        parsed_events.first
      else
        parsed_events
      end
    end

    it "should produce parsable iCal output" do
      expect { ical_roundtrip( FactoryGirl.build(:event) ) }.not_to raise_error
    end

    it "should represent an event without an end time as a 1-hour block" do
      event = FactoryGirl.build(:event, :start_time => now, :end_time => nil)
      expect(event.end_time).to be_blank

      rt = ical_roundtrip(event)
      expect(rt.dtend - rt.dtstart).to eq 1.hour
    end

    it "should set the appropriate end time if one is given" do
      event = FactoryGirl.build(:event, :start_time => now, :end_time => now + 2.hours)

      rt = ical_roundtrip(event)
      expect(rt.dtend - rt.dtstart).to eq 2.hours
    end

    describe "when comparing Event's attributes to its iCalendar output" do
      let(:event) { FactoryGirl.build(:event, :id => 123, :created_at => now) }
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
            expect(model_value.to_i).to eq ical_value.to_i
          else
            expect(model_value).to eq ical_value
          end
        end
      end
    end

    it "should call the URL helper to generate a UID" do
      event = FactoryGirl.build(:event)
      expect(ical_roundtrip(event, :url_helper => lambda {|e| "UID'D!" }).uid).to eq "UID'D!"
    end

    it "should strip HTML from the description" do
      event = FactoryGirl.create(:event, :description => "<blink>OMFG HTML IS TEH AWESOME</blink>")
      expect(ical_roundtrip(event).description).not_to include "<blink>"
    end

    it "should include tags in the description" do
      event = FactoryGirl.build(:event)
      event.tag_list = "tags, folksonomy, categorization"
      expect(ical_roundtrip(event).description).to include event.tag_list.to_s
    end

    it "should leave URL blank if no URL is provided" do
      event = FactoryGirl.build(:event, :url => nil)
      expect(ical_roundtrip(event).url).to be_nil
    end

    it "should have Source URL if URL helper is given)" do
      event = FactoryGirl.build(:event)
      expect(ical_roundtrip(event, :url_helper => lambda{|e| "FAKE"} ).description).to match /FAKE/
    end

    it "should create multi-day entries for multi-day events" do
      time = Time.now
      event = FactoryGirl.build(:event, :start_time => time, :end_time => time + 4.days)
      parsed_event = ical_roundtrip( event )

      start_time = Date.today
      expect(parsed_event.dtstart).to eq start_time
      expect(parsed_event.dtend).to eq(start_time + 5.days)
    end

    describe "sequence" do
      def event_to_ical(event)
        return RiCal.parse_string(Event::IcalRenderer.render([event])).first.events.first
      end

      it "should set an initial sequence on a new event" do
        event = FactoryGirl.create(:event)
        ical = event_to_ical(event)
        expect(ical.sequence).to eq 1
      end

      it "should increment the sequence if it is updated" do
        event = FactoryGirl.create(:event)
        event.update_attribute(:title, "Update 1")
        ical = event_to_ical(event)
        expect(ical.sequence).to eq 2
      end

      # it "should offset the squence based the global SECRETS.icalendar_sequence_offset" do
        # SECRETS.should_receive(:icalendar_sequence_offset).and_return(41)
        # event = FactoryGirl.build(:event)
        # ical = event_to_ical(event)
        # ical.sequence.should eq 42
      # end
    end

    describe "- the headers" do
      before do
        @data = Event::IcalRenderer.render(FactoryGirl.build(:event))
      end

      it "should include the calendar name" do
        expect(@data).to match /\sX-WR-CALNAME:#{SETTINGS.name}\s/
      end

      it "should include the method" do
        expect(@data).to match /\sMETHOD:PUBLISH\s/
      end

      it "should include the scale" do
        expect(@data).to match /\sCALSCALE:Gregorian\s/i
      end
    end
  end
end
