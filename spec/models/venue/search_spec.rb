require 'spec_helper'

describe Venue::Search do
  describe "#venues" do
    before do
      @open_venue = FactoryGirl.create(:venue, title: 'Open Town', description: 'baz', wifi: false, tag_list: %w(foo))
      @closed_venue = FactoryGirl.create(:venue, title: 'Closed Down', closed: true, wifi: false, tag_list: %w(bar))
      @wifi_venue = FactoryGirl.create(:venue, title: "Internetful", wifi: true, tag_list: %w(foo bar))
    end

    describe "with no parameters" do
      subject { Venue::Search.new }

      it "should not include closed venues" do
        subject.venues.should == [@open_venue, @wifi_venue]
      end

      it "should not declare results" do
        subject.results?.should be_falsey
      end
    end

    describe "and showing all venues" do
      it "should include closed venues when asked to with the include_closed parameter" do
        subject = Venue::Search.new all: '1', include_closed: '1'
        subject.venues.should == [@open_venue, @closed_venue, @wifi_venue]
      end

      it "should include ONLY closed venues when asked to with the closed parameter" do
        subject = Venue::Search.new all: '1', closed: '1'
        subject.venues.should == [@closed_venue]
      end

      it "should declare results" do
        subject = Venue::Search.new all: '1'
        subject.results?.should be_truthy
      end
    end

    describe "when searching" do
      describe "for public wifi (and no keyword)" do
        it "should only include results with public wifi" do
          subject = Venue::Search.new query: '', wifi: '1'
          subject.venues.should == [@wifi_venue]
        end

        it "should declare results" do
          subject = Venue::Search.new query: '', wifi: '1'
          subject.results?.should be_truthy
        end
      end

      describe "when searching by keyword" do
        it "should find venues by title" do
          subject = Venue::Search.new query: 'Open Town'
          subject.venues.should == [@open_venue]
        end

        it "should find venues by description" do
          subject = Venue::Search.new query: 'baz'
          subject.venues.should == [@open_venue]
        end

        describe "and requiring public wifi" do
          it "should not find venues without public wifi" do
            subject = Venue::Search.new query: 'baz', wifi: '1'
            subject.venues.should be_empty
          end
        end

        it "should declare results" do
          subject = Venue::Search.new query: 'Open Town'
          subject.results?.should be_truthy
        end
      end
    end

    it "should be able to return events matching specific tag" do
      subject = Venue::Search.new tag: "foo"
      subject.venues.should =~ [@open_venue, @wifi_venue]
    end

    it "should declare results" do
      subject = Venue::Search.new tag: "foo"
      subject.results?.should be_truthy
    end
  end
end
