require File.dirname(__FILE__) + '/../spec_helper'

describe Source, "in general" do
  before(:each) do
    @event = mock_model(Event,
      :title => "Title",
      :description => "Description",
      :url => "http://my.url/",
      :start_time => Time.now + 1.day,
      :end_time => nil,
      :venue => nil,
      :duplicate_of_id => nil)
  end

  it "should create events for source from URL" do
    @event.should_receive(:save!)
    
    source = Source.new(:url => "http://my.url/")
    source.should_receive(:to_events).and_return([@event])
    source.create_events!.should == [@event]
  end

  it "should fail to create events for invalid sources" do
    source = Source.new(:url => '\not valid/')
    lambda{ source.to_events }.should raise_error(ActiveRecord::RecordInvalid, /Url has invalid format/i)
  end
end

describe Source, "when reading name" do
  before(:all) do
    @title = "title"
    @url = "http://my.url/"
  end

  before(:each) do
    @source = Source.new
  end

  it "should return nil if no title is available" do
    @source.name.should be_nil
  end

  it "should use title if available" do
    @source.title = @title
    @source.name.should == @title
  end

  it "should use URL if available" do
    @source.url = @url
    @source.name.should == @url
  end

  it "should prefer to use title over URL if both are available" do
    @source.title = @title
    @source.url = @url

    @source.name.should == @title
  end
end

describe Source, "when parsing URLs" do
  before(:all) do
    @http_url = 'http://upcoming.yahoo.com/event/390164/'
    @ical_url = 'webcal://upcoming.yahoo.com/event/390164/'
    @base_url = 'upcoming.yahoo.com/event/390164/'
  end

  before(:each) do
    @source = Source.new
  end

  it "should not modify supported url schemes" do
    @source.url = @http_url

    @source.url.should == @http_url
  end

  it "should substitute http for unsupported url schemes" do
    @source.url = @ical_url

    @source.url.should == @http_url
  end

  it "should add the http prefix to urls without one" do
    @source.url = @base_url

    @source.url.should == @http_url
  end

  it "should strip leading and trailing whitespace from URL" do
    source = Source.new
    source.url = "     #{@http_url}     "
    source.url.should == @http_url
  end

  it "should be invalid if given invalid URL" do
    source = Source.new
    source.url = '\O.o/'
    source.url.should be_nil
    source.should_not be_valid
  end
end

describe Source, "find_or_create_from" do
  before do
    @url = "http://foo.bar"
  end

  it "should return new, unsaved record if given no arguments" do
    source = Source.find_or_create_from()

    source.should be_a_new_record
  end

  it "should return an existing or newly-created record" do
    record = Source.new(:url => @url)
    Source.should_receive(:find_or_create_by_url).and_return(record)

    result = Source.find_or_create_from(:url => @url)
    record.should == result
  end

  it "should set re-import flag if given" do
    record = Source.new(:url => @url)
    record.should_receive(:save)
    Source.should_receive(:find_or_create_by_url).and_return(record)

    result = Source.find_or_create_from(:url => @url, :reimport => true)
    result.reimport.should be_true
  end
end
