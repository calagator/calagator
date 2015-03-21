require 'spec_helper'

describe Venue::Search, :type => :model do
  describe "#venues" do
    before do
      @open_venue = FactoryGirl.create(:venue, title: 'Open Town', description: 'baz', wifi: false, tag_list: %w(foo))
      @closed_venue = FactoryGirl.create(:venue, title: 'Closed Down', closed: true, wifi: false, tag_list: %w(bar))
      @wifi_venue = FactoryGirl.create(:venue, title: "Internetful", wifi: true, tag_list: %w(foo bar))
    end

    describe "with no parameters" do
      subject { Venue::Search.new }

      it "should not include closed venues" do
        expect(subject.venues).to eq([@open_venue, @wifi_venue])
      end

      it "should not declare results" do
        expect(subject.results?).to be_falsey
      end
    end

    describe "and showing all venues" do
      it "should include closed venues when asked to with the include_closed parameter" do
        subject = Venue::Search.new all: '1', include_closed: '1'
        expect(subject.venues).to eq([@open_venue, @closed_venue, @wifi_venue])
      end

      it "should include ONLY closed venues when asked to with the closed parameter" do
        subject = Venue::Search.new all: '1', closed: '1'
        expect(subject.venues).to eq([@closed_venue])
      end

      it "should declare results" do
        subject = Venue::Search.new all: '1'
        expect(subject.results?).to be_truthy
      end
    end

    describe "when searching" do
      describe "for public wifi (and no keyword)" do
        it "should only include results with public wifi" do
          subject = Venue::Search.new query: '', wifi: '1'
          expect(subject.venues).to eq([@wifi_venue])
        end

        it "should declare results" do
          subject = Venue::Search.new query: '', wifi: '1'
          expect(subject.results?).to be_truthy
        end
      end

      describe "when searching by keyword" do
        it "should find venues by title" do
          subject = Venue::Search.new query: 'Open Town'
          expect(subject.venues).to eq([@open_venue])
        end

        it "should find venues by description" do
          subject = Venue::Search.new query: 'baz'
          expect(subject.venues).to eq([@open_venue])
        end

        describe "and requiring public wifi" do
          it "should not find venues without public wifi" do
            subject = Venue::Search.new query: 'baz', wifi: '1'
            expect(subject.venues).to be_empty
          end
        end

        it "should declare results" do
          subject = Venue::Search.new query: 'Open Town'
          expect(subject.results?).to be_truthy
        end
      end
    end

    it "should be able to return events matching specific tag" do
      subject = Venue::Search.new tag: "foo"
      expect(subject.venues).to match_array([@open_venue, @wifi_venue])
    end

    it "should declare results" do
      subject = Venue::Search.new tag: "foo"
      expect(subject.results?).to be_truthy
    end
  end
end
