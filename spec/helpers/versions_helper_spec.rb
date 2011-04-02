require File.dirname(__FILE__) + '/../spec_helper'
include VersionsHelper

describe VersionsHelper do
  describe "when creating item" do
    before(:each) do
      @item = Venue.create!(:title => "Venue")
    end

    it "should have one version" do
      @item.versions.size.should == 1
    end

    it "should describe create" do
      version = @item.versions[0]
      changes = changes_for(version)
      changes['title'].should == {:current => 'Venue', :previous => nil}
    end

    it "should extract the created title" do
      version = @item.versions[0]
      title_for(version).should == 'Venue'
    end
  end

  describe "when updating a created item" do
    before(:each) do
      @item = Venue.create!(:title => "Venue")
      @item.update_attribute(:title, "My Venue")
    end

    it "should have two versions" do
      @item.versions.size.should == 2
    end

    it "should describe create" do
      version = @item.versions[0]
      changes = changes_for(version)
      changes['title'].should == {:current => 'Venue', :previous => nil}
    end

    it "should describe update" do
      version = @item.versions[1]
      changes = changes_for(version)
      changes['title'].should == {:current => 'My Venue', :previous => 'Venue'}
    end

    it "should extract the previous title" do
      version = @item.versions[1]
      title_for(version).should == 'Venue'
    end
  end

  describe "when deleting an updated item" do
    before(:each) do
      @item = Venue.create!(:title => "Venue")
      @item.update_attribute(:title, "My Venue")
      @item.destroy
    end

    it "should have three versions" do
      @item.versions.size.should == 3
    end

    it "should describe create" do
      version = @item.versions[0]
      changes = changes_for(version)
      changes['title'].should == {:current => 'Venue', :previous => nil}
    end

    it "should describe update" do
      version = @item.versions[1]
      changes = changes_for(version)
      changes['title'].should == {:current => 'My Venue', :previous => 'Venue'}
    end

    it "should describe destroy" do
      version = @item.versions[2]
      changes = changes_for(version)
      changes['title'].should == {:current => nil, :previous => 'My Venue'}
    end

    it "should extract the final title" do
      version = @item.versions[2]
      title_for(version).should == 'My Venue'
    end
  end

  it "should fail on unknown events" do
    item = Venue.create!(:title => "Venue")
    version = item.versions.first
    version.should_receive(:event).any_number_of_times.and_return("omgkittens")

    lambda { changes_for(version) }.should raise_error(ArgumentError)
  end
end
