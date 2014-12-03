require 'spec_helper'

describe Event, :type => :model do
  shared_examples_for "#search" do
    it "returns everything when searching by empty string" do
      event1 = FactoryGirl.create(:event)
      event2 = FactoryGirl.create(:event)
      expect(Event.search("")).to match_array([event1, event2])
    end

    it "searches event titles by substring" do
      event1 = FactoryGirl.create(:event, title: "wtfbbq")
      event2 = FactoryGirl.create(:event, title: "zomg!")
      expect(Event.search("zomg")).to eq([event2])
    end

    it "searches event descriptions by substring" do
      event1 = FactoryGirl.create(:event, description: "wtfbbq")
      event2 = FactoryGirl.create(:event, description: "zomg!")
      expect(Event.search("zomg")).to eq([event2])
    end

    it "searches event tags by exact match" do
      event1 = FactoryGirl.create(:event, tag_list: ["wtf", "bbq", "zomg"])
      event2 = FactoryGirl.create(:event, tag_list: ["wtf", "bbq", "omg"])
      expect(Event.search("omg")).to eq([event2])
    end

    it "does not search multiple terms" do
      event1 = FactoryGirl.create(:event, title: "wtf")
      event2 = FactoryGirl.create(:event, title: "zomg!")
      event3 = FactoryGirl.create(:event, title: "bbq")
      expect(Event.search("wtf zomg")).to match_array([])
    end

    it "searches case-insensitively" do
      event1 = FactoryGirl.create(:event, title: "WTFBBQ")
      event2 = FactoryGirl.create(:event, title: "ZOMG!")
      expect(Event.search("zomg")).to eq([event2])
    end

    it "sorts by start time descending" do
      event2 = FactoryGirl.create(:event, start_time: 1.day.ago)
      event1 = FactoryGirl.create(:event, start_time: 1.day.from_now)
      expect(Event.search("")).to eq([event1, event2])
    end

    it "can sort by event title" do
      event2 = FactoryGirl.create(:event, title: "zomg")
      event1 = FactoryGirl.create(:event, title: "omg")
      expect(Event.search("", order: "name")).to eq([event1, event2])
    end

    it "can sort by venue title" do
      event2 = FactoryGirl.create(:event, venue: FactoryGirl.create(:venue, title: "zomg"))
      event1 = FactoryGirl.create(:event, venue: FactoryGirl.create(:venue, title: "omg"))
      expect(Event.search("", order: "venue")).to eq([event1, event2])
    end

    it "can limit to current and upcoming events" do
      event1 = FactoryGirl.create(:event, start_time: 1.year.ago)
      event2 = FactoryGirl.create(:event, start_time: Time.zone.today)
      event3 = FactoryGirl.create(:event, start_time: 1.year.from_now)
      expect(Event.search("", skip_old: true)).to eq([event3, event2])
    end

    it "can limit number of events" do
      2.times { FactoryGirl.create(:event) }
      expect(Event.search("", limit: 1).count).to eq(1)
    end

    it "limit applies to current and past queries separately" do
      event1 = FactoryGirl.create(:event, title: "omg", start_time: 1.year.ago)
      event2 = FactoryGirl.create(:event, title: "omg", start_time: 1.year.ago)
      event3 = FactoryGirl.create(:event, title: "omg", start_time: 1.year.from_now)
      event4 = FactoryGirl.create(:event, title: "omg", start_time: 1.year.from_now)
      expect(Event.search("omg", limit: 1).to_a.count).to eq(2)
    end

    it "ANDs terms together to narrow search results" do
      event1 = FactoryGirl.create(:event, title: "women who hack")
      event2 = FactoryGirl.create(:event, title: "women who bike")
      event3 = FactoryGirl.create(:event, title: "omg")
      expect(Event.search("women who hack")).to eq([event1])
    end
  end

  describe "Sql" do
    # spec_helper defaults all tests to sql

    it_should_behave_like "#search"

    it "searches event urls by substring" do
      event1 = FactoryGirl.create(:event, url: "http://example.com/wtfbbq.html")
      event2 = FactoryGirl.create(:event, url: "http://example.com/zomg.html")
      expect(Event.search("zomg")).to eq([event2])
    end

    it "is using the sql search engine" do
      expect(Event::SearchEngine.kind).to eq(:sql)
    end
  end

  describe "Sunspot" do
    around do |example|
      server_running = begin
        # Try opening the configured port. If it works, it's running.
        TCPSocket.new('127.0.0.1', Sunspot::Rails.configuration.port).close
        true
      rescue Errno::ECONNREFUSED
        false
      end

      if server_running
        Event::SearchEngine.use(:sunspot)
        Venue::SearchEngine.use(:sunspot)
        Event.reindex
        Venue.reindex
        example.run
      else
        pending "Solr not running. Start with `rake sunspot:solr:start RAILS_ENV=test`"
      end
    end

    it_should_behave_like "#search"

    it "is using the sunspot search engine" do
      expect(Event::SearchEngine.kind).to eq(:sunspot)
    end
  end
end

