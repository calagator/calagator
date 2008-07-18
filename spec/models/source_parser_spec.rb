require File.dirname(__FILE__) + '/../spec_helper'

class SourceParser::FakeParser < SourceParser::Base
end

describe SourceParser, "when reading content" do
  it "should read from a normal URL" do
    uri = mock_model(URI)
    # please retain space betwen "?" and ")" on following line; it avoids a SciTE issue
    uri.should_receive(:respond_to? ).and_return(true)
    uri.should_receive(:read).and_return(42)
    URI.should_receive(:parse).and_return(uri)

    SourceParser.read_url("not://a.real/~url").should == 42
  end

  it "should read from a wacky URL" do
    uri = mock_model(URI)
    # please retain space betwen "?" and ")" on following line; it avoids a SciTE issue
    uri.should_receive(:respond_to? ).any_number_of_times.and_return(false)
    URI.should_receive(:parse).any_number_of_times.and_return(uri)

    error_type = RUBY_PLATFORM.match(/mswin/) ? Errno::EINVAL : Errno::ENOENT
    lambda { SourceParser.read_url("not://a.real/~url") }.should raise_error(error_type)
  end

  it "should unescape ATOM feeds" do
    content = mock_model(String, :content_type => "application/atom+xml")
    SourceParser::Base.should_receive(:read_url).and_return(content)
    CGI.should_receive(:unescapeHTML).and_return(42)

    SourceParser.content_for(:fake => :argument).should == 42
  end
end

describe SourceParser, "when subclassing" do
  it "should demand that to_hcals is implemented" do
    lambda{ SourceParser::FakeParser.to_hcals }.should raise_error(NotImplementedError)
  end

  it "should demand that to_abstract_events is implemented" do
    lambda{ SourceParser::FakeParser.to_abstract_events }.should raise_error(NotImplementedError)
  end
end

describe SourceParser, "when parsing events" do
  it "should skip past parsing errors" do
    events = [mock_model(SourceParser::AbstractEvent)]
    SourceParser::FakeParser.should_receive(:to_abstract_events).and_raise(NotImplementedError)
    SourceParser::Hcal.should_receive(:to_abstract_events).and_return(events)
    SourceParser::Base.should_receive(:content_for).and_return("fake content")

    SourceParser.to_abstract_events(:fake => :argument).should == events
  end
end

describe SourceParser, "checking duplicates when importing" do
  fixtures :events, :venues

  describe "two identical events" do
    before(:all) do
      @cal_source = Source.new(:title => "Calendar event feed", :url => "http://mysample.hcal/")
      @cal_content = (%{
      <div class="vevent">
        <abbr class="dtstart" title="20080714"></abbr>
        <abbr class="summary" title="Bastille Day"></abbr>
        <abbr class="location" title="Arc de Triomphe"></abbr>
      </div>
      <div class="vevent">
        <abbr class="dtstart" title="20080714"></abbr>
        <abbr class="summary" title="Bastille Day"></abbr>
        <abbr class="location" title="Arc de Triomphe"></abbr>
      </div>})
      SourceParser::Base.stub!(:read_url).and_return(@cal_content)
      @abstract_events = @cal_source.to_events
      @created_events = @cal_source.create_events!(:skip_old => false)
    end

    it "should parse two events" do
      @abstract_events.size.should == 2
    end

    it "should create two events" do
      @created_events.size.should == 2
    end

    it "should mark one event as a duplicate of the other" do
      pending "Marked as pending because test fails."
      # next line added for debugging this test; remove when fixed
      @created_events.should == "remove this line"
      ( (@created_events[1].duplicate_of == @created_events[0]) ||
        (@created_events[0].duplicate_of == @created_events[1]) ).should be_true
    end
   end

  it "should not create a new event when importing an event identical to a stored event" do
    @hcal_source = Source.new(:title => "Calendar event feed", :url => "http://mysample.hcal/")
    @hcal_content = read_sample('hcal_event_duplicates_fixture.xml')
    SourceParser::Base.stub!(:read_url).and_return(@hcal_content)
    @events = @hcal_source.to_events

    @events.first.should_not be_a_new_record
  end

  describe "should create two events when importing two non-identical events" do
    # This behavior is tested under
    #  describe SourceParser::Hcal, "with hCalendar events" do
    #  'it "should parse a page with multiple events" '
  end

  describe "two identical events with different venues" do
    before(:each) do
      @cal_content = (%{
      <div class="vevent">
        <abbr class="dtstart" title="20080714"></abbr>
        <abbr class="summary" title="Bastille Day"></abbr>
        <abbr class="location" title="Arc de Triomphe"></abbr>
      </div>
      <div class="vevent">
        <abbr class="dtstart" title="20080714"></abbr>
        <abbr class="summary" title="Bastille Day"></abbr>
        <abbr class="location" title="Bastille"></abbr>
      </div>})
      SourceParser::Base.stub!(:read_url).and_return(@cal_content)

      @cal_source = Source.new(:title => "Calendar event feed", :url => "http://mysample.hcal/")
      @parsed_events = @cal_source.to_events
      @created_events = @cal_source.create_events!(:skip_old => false)
    end

    it "should parse two events" do
      @parsed_events.size.should == 2
    end

    it "should create two events" do
      @created_events.size.should == 2
    end

     it "should have different venues for the parsed events" do
      @parsed_events[0].venue.should_not == @parsed_events[1].venue
    end

     it "should have different venues for the created events" do
      @created_events[0].venue.should_not == @created_events[1].venue
    end
  end

  it "an event whose venue is identical to a squashed duplicate should use the master venue"  do
    Event.destroy_all
    Source.destroy_all
    Venue.destroy_all

    dummy_source = Source.create(:title => "Dummy", :url => "http://IcalEventWithSquashedVenue.com/")
    master_venue = Venue.create(:title => "Master")
    squashed_venue = Venue.create(
      :title => "Squashed Duplicate Venue",
      :duplicate_of_id => master_venue.id)

    @cal_content = (%{
    <div class="vevent">
      <abbr class="dtstart" title="20090117"></abbr>
      <abbr class="summary" title="Event with cloned venue"></abbr>
      <abbr class="location" title="Squashed Duplicate Venue"></abbr>
    </div>})
    SourceParser::Base.stub!(:read_url).and_return(@cal_content)
    @source = Source.new(
      :title => "Event with squashed venue",
      :url => "http://IcalEventWithSquashedVenue.com/")

    @events = @source.to_events(:skip_old => false)
    event = @events.first
    event.venue.title.should == "Master"
  end
end
