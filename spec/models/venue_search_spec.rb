require 'spec_helper'

describe Venue do
  shared_examples_for "#search" do
    it "returns everything when searching by empty string" do
      venue1 = FactoryGirl.create(:venue)
      venue2 = FactoryGirl.create(:venue)
      Venue.search("").should =~ [venue1, venue2]
    end

    it "searches venue titles by substring" do
      venue1 = FactoryGirl.create(:venue, title: "wtfbbq")
      venue2 = FactoryGirl.create(:venue, title: "zomg!")
      Venue.search("zomg").should == [venue2]
    end

    it "searches venue descriptions by substring" do
      venue1 = FactoryGirl.create(:venue, description: "wtfbbq")
      venue2 = FactoryGirl.create(:venue, description: "zomg!")
      Venue.search("zomg").should == [venue2]
    end

    it "searches venue tags by exact match" do
      venue1 = FactoryGirl.create(:venue, tag_list: ["wtf", "bbq", "zomg"])
      venue2 = FactoryGirl.create(:venue, tag_list: ["wtf", "bbq", "omg"])
      Venue.search("omg").should == [venue2]
    end

    it "searches case-insensitively" do
      venue1 = FactoryGirl.create(:venue, title: "WTFBBQ")
      venue2 = FactoryGirl.create(:venue, title: "ZOMG!")
      Venue.search("zomg").should == [venue2]
    end

    it "sorts by title" do
      venue2 = FactoryGirl.create(:venue, title: "zomg")
      venue1 = FactoryGirl.create(:venue, title: "omg")
      Venue.search("", order: "name").should == [venue1, venue2]
    end

    it "can limit to venues with wifi" do
      venue1 = FactoryGirl.create(:venue, wifi: false)
      venue2 = FactoryGirl.create(:venue, wifi: true)
      Venue.search("", wifi: true).should == [venue2]
    end

    it "excludes closed venues" do
      venue1 = FactoryGirl.create(:venue, closed: true)
      venue2 = FactoryGirl.create(:venue, closed: false)
      Venue.search("").should == [venue2]
    end

    it "can include closed venues" do
      venue1 = FactoryGirl.create(:venue, closed: true)
      venue2 = FactoryGirl.create(:venue, closed: false)
      Venue.search("", include_closed: true).should =~ [venue1, venue2]
    end

    it "can limit number of venues" do
      2.times { FactoryGirl.create(:venue) }
      Venue.search("", limit: 1).count.should == 1
    end
  end

  describe "Sql" do
    around do |example|
      original = Venue::SearchEngine.kind
      Venue::SearchEngine.kind = :sql
      example.run
      Venue::SearchEngine.kind = original
    end

    it_should_behave_like "#search"

    it "is using the sql search engine" do
      Venue::SearchEngine.kind.should == :sql
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
        Event::SearchEngine.kind = Venue::SearchEngine.kind = :sunspot
        example.run
      else
        pending "Solr not running. Start with `rake sunspot:solr:start RAILS_ENV=test`"
      end
    end

    it_should_behave_like "#search"

    it "is using the sunspot search engine" do
      Venue::SearchEngine.kind.should == :sunspot
    end
  end
end
