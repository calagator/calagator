require 'spec_helper'

describe SourceParser::Facebook, :type => :model do

  describe "when importing an event" do
    before(:each) do
      content = read_sample('facebook.json')
      parsed_content = MultiJson.decode(content)
      expect(HTTParty).to receive(:get).and_return(parsed_content)
      @events = SourceParser::Facebook.to_abstract_events(:url => 'http://facebook.com/event.php?eid=247619485255249')
      @event = @events.first
    end

    it "should find one event" do
      expect(@events.size).to eq 1
    end

    it "should set event details" do
      expect(@event.title).to eq "Open Source Bridge 2012"
      time = Time.zone.parse("26 Jun 2012 09:00:00 PDT -07:00")
      expect(@event.start_time).to eq time
    end

    it "should tag Facebook events with automagic machine tags" do
      expect(@event.tags).to eq ["facebook:event=247619485255249"]
    end

    it "should set the event url to the original import URL" do
      expect(@event.url).to eq 'http://facebook.com/event.php?eid=247619485255249'
    end

    it "should populate a venue when structured data is provided" do
      expect(@event.location.title).to          eq "Eliot Center"
      expect(@event.location.street_address).to eq "1226 SW Salmon Street"
      expect(@event.location.locality).to       eq "Portland"
      expect(@event.location.region).to         eq "Oregon"
      expect(@event.location.country).to        eq "United States"
      expect(@event.location.latitude.to_s).to  eq "45.5236"
      expect(@event.location.longitude.to_s).to eq "-122.675"
    end
  end

  describe "when parsing Facebook URLs" do
    def should_parse(url)
      expect(url.match(SourceParser::Facebook.url_pattern)[1]).to eq "247619485255249"
    end

    it "should parse a GET-style URL" do
      should_parse 'http://facebook.com/event.php?eid=247619485255249'
    end

    it "should parse a GET-style URL using HTTPS" do
      should_parse 'https://facebook.com/event.php?eid=247619485255249'
    end

    it "should parse a REST-style URL" do
      should_parse 'http://www.facebook.com/events/247619485255249'
    end

    it "should parse a GET-style URL with a 'www.' host prefix" do
      should_parse 'http://www.facebook.com/event.php?eid=247619485255249'
    end

    it "should parse a API uri" do
      should_parse 'http://graph.facebook.com/247619485255249'
    end
  end

end

