require 'spec_helper'

describe Source, "in general", :type => :model do
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
    expect(@event).to receive(:save!)

    source = Source.new(:url => "http://my.url/")
    expect(source).to receive(:to_events).and_return([@event])
    expect(source.create_events!).to eq [@event]
  end

  it "should fail to create events for invalid sources" do
    source = Source.new(:url => '\not valid/')
    expect{ source.to_events }.to raise_error(ActiveRecord::RecordInvalid, /Url has invalid format/i)
  end
end

describe Source, "when reading name", :type => :model do
  before(:each) do
    @title = "title"
    @url = "http://my.url/"
  end

  before(:each) do
    @source = Source.new
  end

  it "should return nil if no title is available" do
    expect(@source.name).to be_nil
  end

  it "should use title if available" do
    @source.title = @title
    expect(@source.name).to eq @title
  end

  it "should use URL if available" do
    @source.url = @url
    expect(@source.name).to eq @url
  end

  it "should prefer to use title over URL if both are available" do
    @source.title = @title
    @source.url = @url

    expect(@source.name).to eq @title
  end
end

describe Source, "when parsing URLs", :type => :model do
  before(:each) do
    @http_url = 'http://upcoming.yahoo.com/event/390164/'
    @ical_url = 'webcal://upcoming.yahoo.com/event/390164/'
    @base_url = 'upcoming.yahoo.com/event/390164/'
  end

  before(:each) do
    @source = Source.new
  end

  it "should not modify supported url schemes" do
    @source.url = @http_url

    expect(@source.url).to eq @http_url
  end

  it "should substitute http for unsupported url schemes" do
    @source.url = @ical_url

    expect(@source.url).to eq @http_url
  end

  it "should add the http prefix to urls without one" do
    @source.url = @base_url

    expect(@source.url).to eq @http_url
  end

  it "should strip leading and trailing whitespace from URL" do
    source = Source.new
    source.url = "     #{@http_url}     "
    expect(source.url).to eq @http_url
  end

  it "should be invalid if given invalid URL" do
    source = Source.new
    source.url = '\O.o/'
    expect(source.url).to be_nil
    expect(source).not_to be_valid
  end
end

describe Source, "find_or_create_from", :type => :model do
  before do
    @url = "http://foo.bar"
  end

  it "should return new, unsaved record if given no arguments" do
    source = Source.find_or_create_from()

    expect(source).to be_a_new_record
  end

  it "should return an existing or newly-created record" do
    record = Source.new(:url => @url)
    expect(Source).to receive(:find_or_create_by_url).and_return(record)

    result = Source.find_or_create_from(:url => @url)
    expect(record).to eq result
  end

  it "should set re-import flag if given" do
    record = Source.new(:url => @url)
    expect(record).to receive(:save)
    expect(Source).to receive(:find_or_create_by_url).and_return(record)

    result = Source.find_or_create_from(:url => @url, :reimport => true)
    expect(result.reimport).to be_truthy
  end
end
