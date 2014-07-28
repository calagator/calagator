require 'spec_helper'

describe ActsAsTaggableOn::Tag do
  describe "handling machine tags" do
    before do
      @valid_machine_tag = ActsAsTaggableOn::Tag.new(:name => 'meetup:group=1234')
      @defunct_machine_tag = ActsAsTaggableOn::Tag.new(:name => 'upcoming:event=1234')
    end

    it "should return an empty hash when the tag is not a machine tag" do
      ActsAsTaggableOn::Tag.new(:name => 'not a machine tag').machine_tag.should eq({})
    end

    it "should parse a machine tag into components" do
      @valid_machine_tag.machine_tag[:namespace].should eq 'meetup'
      @valid_machine_tag.machine_tag[:predicate].should eq 'group'
      @valid_machine_tag.machine_tag[:value].should eq '1234'
    end

    it "should generate a url for supported namespaces/predicates" do
      @valid_machine_tag.machine_tag[:url].should eq "http://www.meetup.com/1234"
    end

    it "should redirect to 'defunct service' page with machine tag url as query param" do
      @defunct_machine_tag.machine_tag[:url].should eq "http://localhost:3000/defunct?url=http://upcoming.yahoo.com/event/1234"
    end
  end
end
