require 'spec_helper'

describe Organization, :type => :model do

  it "should be valid" do
    organization = Organization.new(:title => 'My Event')
    expect(organization).to be_valid
  end

  it "should add an http prefix to urls missing this before save" do
    organization = Organization.new(:title => 'My Event', :url => 'google.com')
    expect(organization).to be_valid
  end

  it "validates blacklisted words" do
    organization = Organization.new(:title => "Foo bar cialis")
    expect(organization).not_to be_valid
  end

  describe "when validating" do
    let(:attributes) { {:title => 'My Organization'} }
    let(:bad_data) { ' blargie ' }
    let(:expected_data) { bad_data.strip }
    [:title, :description, :email, :telephone].each do |field|
      it "should strip whitespace from #{field}" do
        organization = Organization.new(attributes.merge(field => bad_data))
        organization.valid?
        expect(organization.send(field)).to eq(expected_data)
      end
    end

    it "should strip whitespace from url" do
      organization = Organization.new(attributes.merge(:url => bad_data))
      organization.valid?
      expect(organization.url).to eq("http://#{expected_data}")
    end
  end

  describe "when finding exact duplicates" do
    it "should ignore attributes like created_at" do
      organization1 = Organization.create!(:title => "this", :description => "desc",:created_at => Time.now)
      organization2 = Organization.new(    :title => "this", :description => "desc",:created_at => Time.now.yesterday)

      expect(organization2.find_exact_duplicates).to include(organization1)
    end

    it "should ignore source_id" do
      organization1 = Organization.create!(:title => "this", :description => "desc",:source_id => "1")
      organization2 = Organization.new(    :title => "this", :description => "desc",:source_id => "2")

      expect(organization2.find_exact_duplicates).to include(organization1)
    end

    it "should not match non-duplicates" do
      Organization.create!(:title => "this", :description => "desc")
      organization2 = Organization.new(:title => "that", :description => "desc")

      expect(organization2.find_exact_duplicates).to be_blank
    end
  end

  describe "when finding duplicates [integration test]" do
    before do
      @existing = FactoryGirl.create(:organization)
    end

    it "should not match totally different records" do
      FactoryGirl.create(:organization)
      expect(Organization.find_duplicates_by(:title)).to be_empty
    end

    it "should not match similar records when not searching by duplicated fields" do
      FactoryGirl.create :organization, title: @existing.title
      expect(Organization.find_duplicates_by(:description)).to be_empty
    end

    it "should match similar records when searching by duplicated fields" do
      FactoryGirl.create :organization, title: @existing.title
      expect(Organization.find_duplicates_by(:title)).to be_present
    end

    it "should match similar records when searching by :any" do
      FactoryGirl.create :organization, title: @existing.title
      expect(Organization.find_duplicates_by(:any)).to be_present
    end

    it "should not match similar records when searching by multiple fields where not all are duplicated" do
      FactoryGirl.create :organization, title: @existing.title
      expect(Organization.find_duplicates_by([:title, :description])).to be_empty
    end

    it "should match similar records when searching by multiple fields where all are duplicated" do
      FactoryGirl.create(:organization, :title => @existing.title, :description => @existing.description)
      expect(Organization.find_duplicates_by([:title, :description])).to be_present
    end

    it "should not match dissimilar records when searching by :all" do
      FactoryGirl.create(:organization)
      expect(Organization.find_duplicates_by(:all)).to be_empty
    end

    it "should match similar records when searching by :all" do
      attributes = @existing.attributes.reject{ |k,v| k == 'id'}
      Organization.create!(attributes)
      expect(Organization.find_duplicates_by(:all)).to be_present
    end
  end

  describe "when checking for squashing" do
    before do
      @master = Organization.create!(:title => "Master")
      @slave_first = Organization.create!(:title => "1st slave", :duplicate_of_id => @master.id)
      @slave_second = Organization.create!(:title => "2nd slave", :duplicate_of_id => @slave_first.id)
    end

    it "should recognize a master" do
      expect(@master).to be_a_master
    end

    it "should recognize a slave" do
      expect(@slave_first).to be_a_slave
    end

    it "should not think that a slave is a master" do
      expect(@slave_second).not_to be_a_master
    end

    it "should not think that a master is a slave" do
      expect(@master).not_to be_a_slave
    end

    it "should return the progenitor of a child" do
      expect(@slave_first.progenitor).to eq @master
    end

    it "should return the progenitor of a grandchild" do
      expect(@slave_second.progenitor).to eq @master
    end

    it "should return a master as its own progenitor" do
      expect(@master.progenitor).to eq @master
    end
  end

  describe "when squashing duplicates" do
    before do
      @master_organization    = Organization.create!(:title => "Master")
      @submaster_organization = Organization.create!(:title => "Submaster")
      @child_organization     = Organization.create!(:title => "Child", :duplicate_of => @submaster_organization)
      @organizations          = [@master_organization, @submaster_organization, @child_organization]

      @event_from_child_organization = Event.create!(:title => "Event at child organization", :organization => @child_organization, :start_time => Time.now)
      @event_from_submaster_organization = Event.create!(:title => "Event at submaster organization", :organization => @submaster_organization, :start_time => Time.now)
      @events          = [@event_from_child_organization, @event_from_submaster_organization]
    end

    it "should squash a single duplicate" do
      Organization.squash(@master_organization, @submaster_organization)

      expect(@submaster_organization.duplicate_of).to eq @master_organization
      expect(@submaster_organization.duplicate?).to be_truthy
    end

    it "should squash multiple duplicates" do
      Organization.squash(@master_organization, [@submaster_organization, @child_organization])

      expect(@submaster_organization.duplicate_of).to eq @master_organization
      expect(@child_organization.duplicate_of).to eq @master_organization
    end

    it "should squash duplicates recursively" do
      Organization.squash(@master_organization, @submaster_organization)

      expect(@submaster_organization.duplicate_of).to eq @master_organization
      @child_organization.reload # Needed because child was queried through DB, not object graph
      expect(@child_organization.duplicate_of).to eq @master_organization
    end

    it "should transfer events of duplicates" do
      expect(@organizations.map{|organization| organization.events.count}).to eq [0, 1, 1]

      Organization.squash(@master_organization, @submaster_organization)

      expect(@organizations.map{|organization| organization.events.count}).to eq [2, 0, 0]

      events = @organizations.map(&:events).flatten
      expect(events).to be_present
      for event in events
        expect(event.organization).to eq @master_organization
      end
    end
  end
end
