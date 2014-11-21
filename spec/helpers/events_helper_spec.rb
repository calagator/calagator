require 'spec_helper'

describe EventsHelper do
  describe "#icon_exists_for?" do
    it "should return true if there is a PNG file in tag_icons with the name of the argument" do
      helper.icon_exists_for?("pizza").should eq true
    end

    it "should return true if there is not a PNG file in tag_icons with the name of the argument" do
      helper.icon_exists_for?("no_image").should eq false
    end
  end

  shared_context "tag icons" do
    before do
      @event = FactoryGirl.create(:event, :tag_list => ['ruby', 'pizza'])
      @event2 = FactoryGirl.create(:event, :tag_list => ['no_image', 'also_no_image'])
      @untagged_event = Event.new
    end
  end

  describe "#get_tag_icons" do
    include_context "tag icons"

    it "should generate an array of image tags for event tags" do
      helper.get_tag_icons(@event).should eq ["<img alt=\"Ruby\" src=\"/assets/tag_icons/ruby.png\" title=\"ruby\" />", "<img alt=\"Pizza\" src=\"/assets/tag_icons/pizza.png\" title=\"pizza\" />"]
    end

    it "should return nil values for tags that do not correspond to images" do
      helper.get_tag_icons(@event2).should eq [nil, nil]
    end

    it "should return a blank array if event has no tags" do
      helper.get_tag_icons(@untagged_event).should eq []
    end
  end

  describe "#display_tag_icons" do
    include_context "tag icons"

    it "should render image tags inline and whitespace separated" do
      helper.display_tag_icons(@event).should eq '<img alt="Ruby" src="/assets/tag_icons/ruby.png" title="ruby" /> <img alt="Pizza" src="/assets/tag_icons/pizza.png" title="pizza" />'
    end

    it "should render nothing if no image tags" do
      helper.display_tag_icons(@event2).should eq " "
    end

    it "should render nothing if event has no tags" do
      helper.display_tag_icons(@untagged_event).should eq ""
    end
  end

  describe "#events_sort_link" do
    it "renders a sorting link with the field for the supplied key" do
      params.merge! action: "index", controller: "events"
      helper.events_sort_link("score").should == %(<a href="/events?order=score">Relevance</a>)
    end

    it "removes any existing order if no key is entered" do
      params.merge! action: "index", controller: "events", order: "score"
      helper.events_sort_link(nil).should == %(<a href="/events">Default</a>)
    end
  end

  describe "#events_sort_label" do
    it "should return nil without arguments" do
      helper.events_sort_label(nil).should be_nil
    end

    it "should return string for a string key" do
      helper.events_sort_label("score").should == " by <strong>Relevance.</strong>"
    end

    it "should return string for a symbol key" do
      helper.events_sort_label(:score).should == " by <strong>Relevance.</strong>"
    end

    it "should use the label Date when using a tag" do
      assign :tag, ActsAsTaggableOn::Tag.new
      helper.events_sort_label(nil).should == " by <strong>Date.</strong>"
    end
  end

  describe "#today_tomorrow_or_weekday" do
    it "should display day of the week" do
      event = Event.new start_time: "2010-01-01"
      helper.today_tomorrow_or_weekday(event).should == "Friday"
    end

    it "should display tomorrow as 'Tomorrow'" do
      event = Event.new start_time: "2010-01-01", end_time: 1.day.from_now
      helper.today_tomorrow_or_weekday(event).should == "Started Friday"
    end
  end

  describe "google_event_export_link" do
    def escape(string)
      return Regexp.escape(CGI.escape(string))
    end

    shared_context "exported event setup" do
      before do
        @venue = Venue.create!(:title => "My venue", :address => "1930 SW 4th Ave, Portland, Oregon 97201")
        @event = Event.create!(:title => "My event", :start_time => Time.now - 1.hour, :end_time => Time.now, :venue => @venue, :description => event_description)
        @export = helper.google_event_export_link(@event)
      end
    end

    shared_examples_for "exported event" do
      it "should have title" do
        @export.should match /\&text=#{escape(@event.title)}/
      end

      it "should have time range" do
        @export.should match /\&dates=#{helper.format_google_timespan(@event)}/
      end

      it "should have venue title" do
        @export.should match /\&location=#{escape(@event.venue.title)}/
      end

      it "should have venue address" do
        @export.should match /\&location=.+?#{escape(@event.venue.geocode_address)}/
      end
    end

    describe "an event's text doesn't need truncation" do
      let(:event_description) { "My event description." }
      include_context "exported event setup"

      it_should_behave_like "exported event"

      it "should have a complete event description" do
        @export.should match /\&details=.*#{escape(event_description)}/
      end
    end

    describe "an event's text needs truncation" do
      let(:event_description) { "My event description. " * 100 }
      include_context "exported event setup"

      it_should_behave_like "exported event"

      it "should have a truncated event description" do
        @export.should match /\&details=.*#{escape(event_description[0..100])}/
      end

      it "should have a truncated URL" do
        @export.size.should be < event_description.size
      end
    end
  end

  describe "#google_events_subscription_link" do
    def method(*args)
      helper.google_events_subscription_link(*args)
    end

    it "should fail if given unknown options" do
      lambda { method(:omg => :kittens) }.should raise_error ArgumentError
    end

    it "should generate a default link" do
      method.should eq "http://www.google.com/calendar/render?cid=http%3A%2F%2Ftest.host%2Fevents.ics"
    end

    it "should generate a search link" do
      method(:query => "my query").should eq "http://www.google.com/calendar/render?cid=http%3A%2F%2Ftest.host%2Fevents%2Fsearch.ics%3Fquery%3Dmy%2Bquery"
    end

    it "should generate a tag link" do
      method(:tag => "mytag").should eq "http://www.google.com/calendar/render?cid=http%3A%2F%2Ftest.host%2Fevents%2Fsearch.ics%3Ftag%3Dmytag"
    end
  end

  describe "#icalendar_feed_link" do
    def method(*args)
      helper.icalendar_feed_link(*args)
    end

    it "should fail if given unknown options" do
      lambda { method(:omg => :kittens) }.should raise_error ArgumentError
    end

    it "should generate a default link" do
      method.should eq "webcal://test.host/events.ics"
    end

    it "should generate a search link" do
      method(:query => "my query").should eq "webcal://test.host/events/search.ics?query=my+query"
    end

    it "should generate a tag link" do
      method(:tag => "mytag").should eq "webcal://test.host/events/search.ics?tag=mytag"
    end
  end

  describe "#icalendar_export_link" do
    def method(*args)
      helper.icalendar_export_link(*args)
    end

    it "should fail if given unknown options" do
      lambda { method(:omg => :kittens) }.should raise_error ArgumentError
    end

    it "should generate a default link" do
      method.should eq "http://test.host/events.ics"
    end

    it "should generate a search link" do
      method(:query => "my query").should eq "http://test.host/events/search.ics?query=my+query"
    end

    it "should generate a tag link" do
      method(:tag => "mytag").should eq "http://test.host/events/search.ics?tag=mytag"
    end
  end

  describe "#atom_feed_link" do
    def method(*args)
      helper.atom_feed_link(*args)
    end

    it "should fail if given unknown options" do
      lambda { method(:omg => :kittens) }.should raise_error ArgumentError
    end

    it "should generate a default link" do
      method.should eq "http://test.host/events.atom"
    end

    it "should generate a search link" do
      method(:query => "my query").should eq "http://test.host/events/search.atom?query=my+query"
    end

    it "should generate a tag link" do
      method(:tag => "mytag").should eq "http://test.host/events/search.atom?tag=mytag"
    end
  end

  describe "#tweet_text" do
    it "contructs a tweet" do
      event = FactoryGirl.create(:event,
        title: "hip and/or hop",
        start_time: "2010-01-01 12:00:00",
        end_time: "2010-01-02 12:00:00")
      event.venue = FactoryGirl.create(:venue, title: "holocene")
      tweet_text(event).should == "hip and/or hop - 12:00PM 01.01.2010 @ holocene"
    end
  end

  describe "format_google_timespan" do
    it "should use the google time format" do
      event = Event.new(
        start_time: '2013-05-13T05:00:00z',
        end_time: '2013-05-13T15:30:00z',
      )

      helper.format_google_timespan(event).should eq \
        "20130513T050000Z/20130513T153000Z"
    end

    it "should the end time to the start time" do
      event = Event.new(start_time: '2014-07-26T13:00:00-0700')
      helper.format_google_timespan(event).should eq \
        "20140726T200000Z/20140726T200000Z"
    end
  end

  describe "sorting labels" do
    it "should display human-friendly label for a known value" do
      helper.sorting_label_for('name').should eq 'Event Name'
    end

    it "should display a default label" do
      helper.sorting_label_for(nil).should eq 'Relevance'
    end

    it "should display a different default label when searching by tag" do
      helper.sorting_label_for(nil, true).should eq 'Date'
    end
  end
end
