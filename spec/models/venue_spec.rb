require 'spec_helper'

# TODO consider converting this to nested describe statements, similar to event_spec

describe Venue do

  it "should be valid" do
    venue = Venue.new(:title => 'My Event')
    venue.should be_valid
  end

  it "should add an http prefix to urls missing this before save" do
    venue = Venue.new(:title => 'My Event', :url => 'google.com')
    venue.should be_valid
  end

  describe "when validating" do
    let(:attributes) { {:title => 'My Venue'} }
    let(:bad_data) { ' blargie ' }
    let(:expected_data) { bad_data.strip }
    [:title, :description, :address, :street_address, :locality, :region, :postal_code, :country, :email, :telephone].each do |field|
      it "should strip whitespace from #{field}" do
        venue = Venue.new(attributes.merge(field => bad_data))
        venue.valid?
        venue.send(field).should == expected_data
      end
    end

    it "should strip whitespace from url" do
      venue = Venue.new(attributes.merge(:url => bad_data))
      venue.valid?
      venue.url.should == "http://#{expected_data}"
    end
  end

end

describe Venue, "when finding exact duplicates" do
  it "should ignore attributes like created_at" do
    venue1 = Venue.create!(:title => "this", :description => "desc",:created_at => Time.now)
    venue2 = Venue.new(    :title => "this", :description => "desc",:created_at => Time.now.yesterday)

    venue2.find_exact_duplicates.should include(venue1)
  end

  it "should ignore source_id" do
    venue1 = Venue.create!(:title => "this", :description => "desc",:source_id => "1")
    venue2 = Venue.new(    :title => "this", :description => "desc",:source_id => "2")

    venue2.find_exact_duplicates.should include(venue1)
  end

  it "should not match non-duplicates" do
    venue1 = Venue.create!(:title => "this", :description => "desc")
    venue2 = Venue.new(    :title => "that", :description => "desc")

    venue2.find_exact_duplicates.should be_blank
  end
end

describe Venue, "with finding unmarked duplicates" do
  it "should find all venues with duplicate titles" do
    Venue.should_receive(:find_by_sql).with("SELECT DISTINCT a.* from venues a, venues b WHERE a.id <> b.id AND ( a.title = b.title )")
    Venue.find_duplicates_by(:title )
  end

  it "should find all venues with duplicate titles and urls" do
    Venue.should_receive(:find_by_sql).with("SELECT DISTINCT a.* from venues a, venues b WHERE a.id <> b.id AND ( a.title = b.title AND a.url = b.url )")
    Venue.find_duplicates_by([:title,:url])
  end
end

describe Venue, "when finding duplicates [integration test]" do
  before do
    @existing = Factory(:venue)
  end

  it "should not match totally different records" do
    record = Factory(:venue)
    Venue.find_duplicates_by(:title).should be_empty
  end

  it "should not match similar records when not searching by duplicated fields" do
    record = Factory(:venue, :title => @existing.title)
    Venue.find_duplicates_by(:description).should be_empty
  end

  it "should match similar records when searching by duplicated fields" do
    record = Factory(:venue, :title => @existing.title)
    Venue.find_duplicates_by(:title).should be_present
  end

  it "should match similar records when searching by :any" do
    record = Factory(:venue, :title => @existing.title)
    Venue.find_duplicates_by(:title).should be_present
  end

  it "should not match similar records when searching by multiple fields where not all are duplicated" do
    record = Factory(:venue, :title => @existing.title)
    Venue.find_duplicates_by([:title, :description]).should be_empty
  end

  it "should match similar records when searching by multiple fields where all are duplicated" do
    record = Factory(:venue, :title => @existing.title, :description => @existing.description)
    Venue.find_duplicates_by([:title, :description]).should be_present
  end

  it "should not match dissimilar records when searching by :all" do
    record = Factory(:venue)
    Venue.find_duplicates_by(:all).should be_empty
  end

  it "should match similar records when searching by :all" do
    attributes = @existing.attributes.reject{ |k,v| k == 'id'}
    Venue.create!(attributes)
    Venue.find_duplicates_by(:all).should be_present
  end
end

describe Venue, "when checking for squashing" do
  before do
    @master = Venue.create!(:title => "Master")
    @slave_first = Venue.create!(:title => "1st slave", :duplicate_of_id => @master.id)
    @slave_second = Venue.create!(:title => "2nd slave", :duplicate_of_id => @slave_first.id)
  end

  it "should recognize a master" do
    @master.should be_a_master
  end

  it "should recognize a slave" do
    @slave_first.should be_a_slave
  end

  it "should not think that a slave is a master" do
    @slave_second.should_not be_a_master
  end

  it "should not think that a master is a slave" do
    @master.should_not be_a_slave
  end

  it "should return the progenitor of a child" do
    @slave_first.progenitor.should eq @master
  end

  it "should return the progenitor of a grandchild" do
    @slave_second.progenitor.should eq @master
  end

  it "should return a master as its own progenitor" do
    @master.progenitor.should eq @master
  end

  it "should return the progenitor if an imported venue has an exact duplicate" do
    @abstract_location = SourceParser::AbstractLocation.new
    @abstract_location.title = @slave_second.title

    Venue.from_abstract_location(@abstract_location).should eq @master
  end

end

describe Venue, "when squashing duplicates" do
  before do
    @master_venue    = Venue.create!(:title => "Master")
    @submaster_venue = Venue.create!(:title => "Submaster")
    @child_venue     = Venue.create!(:title => "Child", :duplicate_of => @submaster_venue)
    @venues          = [@master_venue, @submaster_venue, @child_venue]

    @event_at_child_venue = Event.create!(:title => "Event at child venue", :venue => @child_venue, :start_time => Time.now)
    @event_at_submaster_venue = Event.create!(:title => "Event at submaster venue", :venue => @submaster_venue, :start_time => Time.now)
    @events          = [@event_at_child_venue, @event_at_submaster_venue]

    @venues.map(&:reload) # Make venues recognize changes to associated events
  end

  it "should squash a single duplicate" do
    Venue.squash(:master => @master_venue, :duplicates => @submaster_venue)

    @submaster_venue.duplicate_of.should eq @master_venue
    @submaster_venue.duplicate?.should be_true
  end

  it "should squash multiple duplicates" do
    Venue.squash(:master => @master_venue, :duplicates => [@submaster_venue, @child_venue])

    @submaster_venue.duplicate_of.should eq @master_venue
    @child_venue.duplicate_of.should eq @master_venue
  end

  it "should squash duplicates recursively" do
    Venue.squash(:master => @master_venue, :duplicates => @submaster_venue)

    @submaster_venue.duplicate_of.should eq @master_venue
    @child_venue.reload # Needed because child was queried through DB, not object graph
    @child_venue.duplicate_of.should eq @master_venue
  end

  it "should transfer events of duplicates" do
    @venues.map{|venue| venue.events.count}.should eq [0, 1, 1]

    Venue.squash(:master => @master_venue, :duplicates => @submaster_venue)

    @venues.map(&:reload)
    @venues.map{|venue| venue.events.count}.should eq [2, 0, 0]

    events = @venues.map(&:events).flatten
    events.should be_present
    for event in events
      event.venue.should eq @master_venue
    end
  end

  it "should squash duplicates by ID" do
    Venue.squash(:master => @master_venue.id, :duplicates => @submaster_venue.id)

    @submaster_venue.reload
    @master_venue.reload
    @submaster_venue.duplicate_of.should eq @master_venue
  end
end

describe "Venue geocoding" do
  before do
    @venue = Venue.new(:title => "title", :address => "test")
    @geo_failure = mock("geo", :success => false)
    @geo_success = mock("geo", :success => true, :lat => 0.0, :lng => 0.0,
                        :street_address => "622 SE Grand Ave.", :city => "Portland",
                        :state => "OR", :country_code => "US", :zip => "97214")
    @geocodable_address = "#{@geo_success.street_address}, #{@geo_success.city}" \
                          "#{@geo_success.state} #{@geo_success.zip}"
  end

  it "should be valid even if not yet geocoded" do
    @venue.valid?.should be_true
  end

  it "should report its location properly if it has one" do
    lambda {
      @venue.latitude = 45.0
      @venue.longitude = -122.0
    }.should change { @venue.location }.from(nil).to([BigDecimal("45.0"), BigDecimal("-122.0")])
  end

  it "should geocode automatically on save" do
    Venue.with_geocoding do
      GeoKit::Geocoders::MultiGeocoder.should_receive(:geocode).once.and_return(@geo_success)
      @venue.save
    end
  end

  it "shouldn't geocode automatically unless there's an address" do
    Venue.with_geocoding do
      @venue.address = ""
      GeoKit::Geocoders::MultiGeocoder.should_not_receive(:geocode)
      @venue.save
    end
  end

  it "shouldn't geocode automatically if already geocoded" do
    Venue.with_geocoding do
      @venue.latitude = @venue.longitude = 0.0
      GeoKit::Geocoders::MultiGeocoder.should_not_receive(:geocode)
      @venue.save
    end
  end

  it "shouldn't fail if the geocoder returns failure" do
    Venue.with_geocoding do
      GeoKit::Geocoders::MultiGeocoder.should_receive(:geocode).once.and_return(@geo_failure)
      @venue.save
    end
  end

  it "should fill in empty addressing fields" do
    Venue.with_geocoding do
      GeoKit::Geocoders::MultiGeocoder.should_receive(:geocode).once.and_return(@geo_success)
      @venue.save
      @venue.street_address.should eq @geo_success.street_address
      @venue.locality.should eq @geo_success.city
      @venue.region.should eq @geo_success.state
      @venue.postal_code.should eq @geo_success.zip
    end
  end

  it "should leave non-empty addressing fields alone" do
    Venue.with_geocoding do
      @venue.locality = "Cleveland"
      GeoKit::Geocoders::MultiGeocoder.should_receive(:geocode).once.and_return(@geo_success)
      @venue.save
      @venue.locality.should eq "Cleveland"
    end
  end

  it "should strip location when geocoding is forced" do
    @venue.force_geocoding=true
    @venue.latitude.should be_nil
    @venue.longitude.should be_nil
  end
end

describe "Venue geocode addressing" do
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
    @venue.geocode_address.should eq "street_address, locality region postal_code country"
  end

  it "should fall back to 'address' field if street address fields are blank" do
    @venue.attributes = {:street_address => "", :address => "address"}
    @venue.geocode_address.should eq "address"
  end

  describe "when versioning" do
    it "should have versions" do
      Venue.new.versions.should eq []
    end

    it "should create a new version after updating" do
      venue = Factory.create :venue
      venue.versions.count.should eq 1

      venue.title += " (change)"

      venue.save!
      venue.versions.count.should eq 2
    end

    it "should store old content in past versions" do
      venue = Factory.create :venue
      original_title = venue.title

      venue.title += " (change)"

      venue.save!
      venue.versions.last.reify.title.should eq original_title
    end
  end
end
