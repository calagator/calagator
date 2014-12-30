require 'spec_helper'

describe Venue, :type => :model do

  it "should be valid" do
    venue = Venue.new(:title => 'My Event')
    expect(venue).to be_valid
  end

  it "should add an http prefix to urls missing this before save" do
    venue = Venue.new(:title => 'My Event', :url => 'google.com')
    expect(venue).to be_valid
  end

  it "validates blacklisted words" do
    venue = Venue.new(:title => "Foo bar cialis")
    expect(venue).not_to be_valid
  end

  describe 'latitude validation' do
    specify do
      venue = Venue.new(:latitude => -91)
      expect(venue).to have(1).error_on(:latitude)
    end

    specify do
      venue = Venue.new(:latitude => -89)
      expect(venue).to have(0).errors_on(:latitude)
    end
  end

  describe 'longitude validation' do
    specify do
      venue = Venue.new(:longitude => -181)
      expect(venue).to have(1).error_on(:longitude)
    end

    specify do
      venue = Venue.new(:longitude => -179)
      expect(venue).to have(0).errors_on(:longitude)
    end
  end

  describe "when validating" do
    let(:attributes) { {:title => 'My Venue'} }
    let(:bad_data) { ' blargie ' }
    let(:expected_data) { bad_data.strip }
    [:title, :description, :address, :street_address, :locality, :region, :postal_code, :country, :email, :telephone].each do |field|
      it "should strip whitespace from #{field}" do
        venue = Venue.new(attributes.merge(field => bad_data))
        venue.valid?
        expect(venue.send(field)).to eq(expected_data)
      end
    end

    it "should strip whitespace from url" do
      venue = Venue.new(attributes.merge(:url => bad_data))
      venue.valid?
      expect(venue.url).to eq("http://#{expected_data}")
    end
  end

  describe "when finding exact duplicates" do
    it "should ignore attributes like created_at" do
      venue1 = Venue.create!(:title => "this", :description => "desc",:created_at => Time.now)
      venue2 = Venue.new(    :title => "this", :description => "desc",:created_at => Time.now.yesterday)

      expect(venue2.find_exact_duplicates).to include(venue1)
    end

    it "should ignore source_id" do
      venue1 = Venue.create!(:title => "this", :description => "desc",:source_id => "1")
      venue2 = Venue.new(    :title => "this", :description => "desc",:source_id => "2")

      expect(venue2.find_exact_duplicates).to include(venue1)
    end

    it "should not match non-duplicates" do
      Venue.create!(:title => "this", :description => "desc")
      venue2 = Venue.new(:title => "that", :description => "desc")

      expect(venue2.find_exact_duplicates).to be_blank
    end
  end

  describe "when finding duplicates [integration test]" do
    before do
      @existing = FactoryGirl.create(:venue)
    end

    it "should not match totally different records" do
      FactoryGirl.create(:venue)
      expect(Venue.find_duplicates_by(:title)).to be_empty
    end

    it "should not match similar records when not searching by duplicated fields" do
      FactoryGirl.create :venue, title: @existing.title
      expect(Venue.find_duplicates_by(:description)).to be_empty
    end

    it "should match similar records when searching by duplicated fields" do
      FactoryGirl.create :venue, title: @existing.title
      expect(Venue.find_duplicates_by(:title)).to be_present
    end

    it "should match similar records when searching by :any" do
      FactoryGirl.create :venue, title: @existing.title
      expect(Venue.find_duplicates_by(:any)).to be_present
    end

    it "should not match similar records when searching by multiple fields where not all are duplicated" do
      FactoryGirl.create :venue, title: @existing.title
      expect(Venue.find_duplicates_by([:title, :description])).to be_empty
    end

    it "should match similar records when searching by multiple fields where all are duplicated" do
      FactoryGirl.create(:venue, :title => @existing.title, :description => @existing.description)
      expect(Venue.find_duplicates_by([:title, :description])).to be_present
    end

    it "should not match dissimilar records when searching by :all" do
      FactoryGirl.create(:venue)
      expect(Venue.find_duplicates_by(:all)).to be_empty
    end

    it "should match similar records when searching by :all" do
      attributes = @existing.attributes.reject{ |k,v| k == 'id'}
      Venue.create!(attributes)
      expect(Venue.find_duplicates_by(:all)).to be_present
    end
  end

  describe "when checking for squashing" do
    before do
      @master = Venue.create!(:title => "Master")
      @slave_first = Venue.create!(:title => "1st slave", :duplicate_of_id => @master.id)
      @slave_second = Venue.create!(:title => "2nd slave", :duplicate_of_id => @slave_first.id)
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
      @master_venue    = Venue.create!(:title => "Master")
      @submaster_venue = Venue.create!(:title => "Submaster")
      @child_venue     = Venue.create!(:title => "Child", :duplicate_of => @submaster_venue)
      @venues          = [@master_venue, @submaster_venue, @child_venue]

      @event_at_child_venue = Event.create!(:title => "Event at child venue", :venue => @child_venue, :start_time => Time.now)
      @event_at_submaster_venue = Event.create!(:title => "Event at submaster venue", :venue => @submaster_venue, :start_time => Time.now)
      @events          = [@event_at_child_venue, @event_at_submaster_venue]
    end

    it "should squash a single duplicate" do
      Venue.squash(@master_venue, @submaster_venue)

      expect(@submaster_venue.duplicate_of).to eq @master_venue
      expect(@submaster_venue.duplicate?).to be_truthy
    end

    it "should squash multiple duplicates" do
      Venue.squash(@master_venue, [@submaster_venue, @child_venue])

      expect(@submaster_venue.duplicate_of).to eq @master_venue
      expect(@child_venue.duplicate_of).to eq @master_venue
    end

    it "should squash duplicates recursively" do
      Venue.squash(@master_venue, @submaster_venue)

      expect(@submaster_venue.duplicate_of).to eq @master_venue
      @child_venue.reload # Needed because child was queried through DB, not object graph
      expect(@child_venue.duplicate_of).to eq @master_venue
    end

    it "should transfer events of duplicates" do
      expect(@venues.map{|venue| venue.events.count}).to eq [0, 1, 1]

      Venue.squash(@master_venue, @submaster_venue)

      expect(@venues.map{|venue| venue.events.count}).to eq [2, 0, 0]

      events = @venues.map(&:events).flatten
      expect(events).to be_present
      for event in events
        expect(event.venue).to eq @master_venue
      end
    end
  end
end

describe "Venue geocoding", :type => :model do
  before do
    @venue = Venue.new(:title => "title", :address => "test")
    @geo_failure = double("geo", :success => false)
    @geo_success = double("geo", :success => true, :lat => 0.0, :lng => 0.0,
                        :street_address => "622 SE Grand Ave.", :city => "Portland",
                        :state => "OR", :country_code => "US", :zip => "97214")
    @geocodable_address = "#{@geo_success.street_address}, #{@geo_success.city}" \
                          "#{@geo_success.state} #{@geo_success.zip}"
  end

  it "should be valid even if not yet geocoded" do
    expect(@venue.valid?).to be_truthy
  end

  it "should report its location properly if it has one" do
    expect {
      @venue.latitude = 45.0
      @venue.longitude = -122.0
    }.to change { @venue.location }.from(nil).to([BigDecimal("45.0"), BigDecimal("-122.0")])
  end

  describe "with geocoding" do
    # Enable geocoding for just these tests
    around do |example|
      original = Venue::Geocoder.perform_geocoding?
      Venue::Geocoder.perform_geocoding = true
      example.run
      Venue::Geocoder.perform_geocoding = original
    end

    it "should geocode automatically on save" do
      expect(GeoKit::Geocoders::MultiGeocoder).to receive(:geocode).once.and_return(@geo_success)
      @venue.save
    end

    it "shouldn't geocode automatically unless there's an address" do
      @venue.address = ""
      expect(GeoKit::Geocoders::MultiGeocoder).not_to receive(:geocode)
      @venue.save
    end

    it "shouldn't geocode automatically if already geocoded" do
      @venue.latitude = @venue.longitude = 0.0
      expect(GeoKit::Geocoders::MultiGeocoder).not_to receive(:geocode)
      @venue.save
    end

    it "shouldn't fail if the geocoder returns failure" do
      expect(GeoKit::Geocoders::MultiGeocoder).to receive(:geocode).once.and_return(@geo_failure)
      @venue.save
    end

    it "should fill in empty addressing fields" do
      expect(GeoKit::Geocoders::MultiGeocoder).to receive(:geocode).once.and_return(@geo_success)
      @venue.save
      expect(@venue.street_address).to eq @geo_success.street_address
      expect(@venue.locality).to eq @geo_success.city
      expect(@venue.region).to eq @geo_success.state
      expect(@venue.postal_code).to eq @geo_success.zip
    end

    it "should leave non-empty addressing fields alone" do
      @venue.locality = "Cleveland"
      expect(GeoKit::Geocoders::MultiGeocoder).to receive(:geocode).once.and_return(@geo_success)
      @venue.save
      expect(@venue.locality).to eq "Cleveland"
    end
  end
end

describe "Venue geocode addressing", :type => :model do
  before do
    @venue = Venue.new(:title => "title")
  end

  it "should use the street address fields if they're present" do
    @venue.attributes = {
      :street_address => "street_address",
      :locality => "locality",
      :region => "region",
      :postal_code => "postal_code",
      :country => "country",
      :address => "address"
    }
    expect(@venue.geocode_address).to eq "street_address, locality region postal_code country"
  end

  it "should fall back to 'address' field if street address fields are blank" do
    @venue.attributes = {:street_address => "", :address => "address"}
    expect(@venue.geocode_address).to eq "address"
  end

  describe "when versioning" do
    it "should have versions" do
      expect(Venue.new.versions).to eq []
    end

    it "should create a new version after updating" do
      venue = FactoryGirl.create :venue
      expect(venue.versions.count).to eq 1

      venue.title += " (change)"

      venue.save!
      expect(venue.versions.count).to eq 2
    end

    it "should store old content in past versions" do
      venue = FactoryGirl.create :venue
      original_title = venue.title

      venue.title += " (change)"

      venue.save!
      expect(venue.versions.last.reify.title).to eq original_title
    end
  end
end
