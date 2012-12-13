require 'spec_helper'

describe ActsAsTaggableOn::Tag do
  describe "handling machine tags" do
    before do
      @valid_machine_tag = ActsAsTaggableOn::Tag.new(:name => 'upcoming:event=1234')
    end

    it "should return an empty hash when the tag is not a machine tag" do
      ActsAsTaggableOn::Tag.new(:name => 'not a machine tag').machine_tag.should eq({})
    end

    it "should parse a machine tag into components" do
      @valid_machine_tag.machine_tag[:namespace].should eq 'upcoming'
      @valid_machine_tag.machine_tag[:predicate].should eq 'event'
      @valid_machine_tag.machine_tag[:value].should eq '1234'
    end

    it "should generate a url for supported namespaces/predicates" do
      @valid_machine_tag.machine_tag[:url].should eq "http://upcoming.yahoo.com/event/1234"
    end
  end
end
