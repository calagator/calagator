require 'spec_helper'

describe Organization, :type => :model do
  shared_examples_for "#search" do
    it "returns everything when searching by empty string" do
      organization1 = FactoryGirl.create(:organization)
      organization2 = FactoryGirl.create(:organization)
      expect(Organization.search("")).to match_array([organization1, organization2])
    end

    it "searches organization titles by substring" do
      organization1 = FactoryGirl.create(:organization, title: "wtfbbq")
      organization2 = FactoryGirl.create(:organization, title: "zomg!")
      expect(Organization.search("zomg")).to eq([organization2])
    end

    it "searches organization descriptions by substring" do
      organization1 = FactoryGirl.create(:organization, description: "wtfbbq")
      organization2 = FactoryGirl.create(:organization, description: "zomg!")
      expect(Organization.search("zomg")).to eq([organization2])
    end

    it "searches organization tags by exact match" do
      organization1 = FactoryGirl.create(:organization, tag_list: ["wtf", "bbq", "zomg"])
      organization2 = FactoryGirl.create(:organization, tag_list: ["wtf", "bbq", "omg"])
      expect(Organization.search("omg")).to eq([organization2])
    end

    it "searches case-insensitively" do
      organization1 = FactoryGirl.create(:organization, title: "WTFBBQ")
      organization2 = FactoryGirl.create(:organization, title: "ZOMG!")
      expect(Organization.search("zomg")).to eq([organization2])
    end

    it "sorts by title" do
      organization2 = FactoryGirl.create(:organization, title: "zomg")
      organization1 = FactoryGirl.create(:organization, title: "omg")
      expect(Organization.search("", order: "name")).to eq([organization1, organization2])
    end

    it "can limit number of organizations" do
      2.times { FactoryGirl.create(:organization) }
      expect(Organization.search("", limit: 1).count).to eq(1)
    end

    it "does not search multiple terms" do
      organization2 = FactoryGirl.create(:organization, title: "zomg")
      organization1 = FactoryGirl.create(:organization, title: "omg")
      expect(Organization.search("zomg omg")).to eq([])
    end

    it "ANDs terms together to narrow search results" do
      organization2 = FactoryGirl.create(:organization, title: "zomg omg")
      organization1 = FactoryGirl.create(:organization, title: "zomg cats")
      expect(Organization.search("zomg omg")).to eq([organization2])
    end

  end

  describe "Sql" do
    around do |example|
      original = Organization::SearchEngine.kind
      Organization::SearchEngine.kind = :sql
      example.run
      Organization::SearchEngine.kind = original
    end

    it_should_behave_like "#search"

    it "is using the sql search engine" do
      expect(Organization::SearchEngine.kind).to eq(:sql)
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
        Organization::SearchEngine.use(:sunspot)
        Event.reindex
        Organization.reindex
        example.run
      else
        pending "Solr not running. Start with `rake sunspot:solr:start RAILS_ENV=test`"
      end
    end

    it_should_behave_like "#search"

    it "is using the sunspot search engine" do
      expect(Organization::SearchEngine.kind).to eq(:sunspot)
    end
  end
end
