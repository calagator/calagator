require 'spec_helper'

describe Organization::Search, :type => :model do
  describe "#organizations" do
    before do
      @regular_organization = FactoryGirl.create(:organization, title: 'Open Town', description: 'baz', tag_list: %w(foo))
    end

    describe "with no parameters" do
      subject { Organization::Search.new }

      it "should not declare results" do
        expect(subject.results?).to be_falsey
      end
    end

    describe "and showing all organizations" do
      it "should declare results" do
        subject = Organization::Search.new all: '1'
        expect(subject.results?).to be_truthy
      end
    end

    describe "when searching" do
      describe "when searching by keyword" do
        it "should find organizations by title" do
          subject = Organization::Search.new query: 'Open Town'
          expect(subject.organizations).to eq([@regular_organization])
        end

        it "should find organizations by description" do
          subject = Organization::Search.new query: 'baz'
          expect(subject.organizations).to eq([@regular_organization])
        end

        it "should declare results" do
          subject = Organization::Search.new query: 'Open Town'
          expect(subject.results?).to be_truthy
        end
      end
    end

    it "should be able to return events matching specific tag" do
      subject = Organization::Search.new tag: "foo"
      expect(subject.organizations).to match_array([@regular_organization])
    end

    it "should declare results" do
      subject = Organization::Search.new tag: "foo"
      expect(subject.results?).to be_truthy
    end
  end
end
