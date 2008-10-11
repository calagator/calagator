require File.dirname(__FILE__) + '/../spec_helper'

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
    Venue.should_receive(:find_by_sql).with("SELECT DISTINCT a.* from venues a, venues b WHERE a.id <> b.id AND ( a.title = b.title ) ORDER BY a.title")
    Venue.find(:duplicates, :by => :title )
  end

  it "should find all venues with duplicate titles and urls" do
    Venue.should_receive(:find_by_sql).with("SELECT DISTINCT a.* from venues a, venues b WHERE a.id <> b.id AND ( a.title = b.title AND a.url = b.url ) ORDER BY a.title,a.url")
    Venue.find(:duplicates, :by => [:title,:url])
  end

  it "should find all venues that have not been marked as duplicate" do
    Venue.should_receive(:find_without_duplicate_support).with(:all, {})
    Venue.find(:non_duplicates)
  end

  it "should find all venues that have been marked as duplicate" do
    Venue.should_receive(:find_without_duplicate_support).with(:all, {})
    Venue.find(:marked_duplicates)
  end

end

describe Venue, "with finding unmarked duplicates (integration test)" do
  fixtures :venues

  before(:each) do
    @venue = venues(:cubespace)
  end

  # Find duplicates, create another venue with the given attributes, and find duplicates again
  def find_duplicates_create_a_clone_and_find_again(find_duplicates_arguments, clone_attributes, create_class = Venue)
    before_results = create_class.find(:duplicates, :by => find_duplicates_arguments)
    clone = create_class.new(clone_attributes)
    clone.stub!(:geocode)
    clone.save!
    after_results = Venue.find(:duplicates, :by => find_duplicates_arguments)
    return [before_results.sort_by(&:created_at), after_results.sort_by(&:created_at)]
  end

  it "should find duplicate title by title" do
    pre, post = find_duplicates_create_a_clone_and_find_again(:title, :title => @venue.title)
    post.size.should == pre.size + 2
  end

  it "should find duplicate title by any" do
    pre, post = find_duplicates_create_a_clone_and_find_again(:any, :title => @venue.title)
    post.size.should == pre.size + 2
  end

  it "should not find duplicate title by address" do
    pre, post = find_duplicates_create_a_clone_and_find_again(:address, :title => @venue.title)
    post.size.should == pre.size
  end

  it "should find complete duplicates by all" do
    pre, post = find_duplicates_create_a_clone_and_find_again(:all, @venue.attributes)
    post.size.should == pre.size + 2
  end

  it "should not find incomplete duplicates by all" do
    pre, post = find_duplicates_create_a_clone_and_find_again(:all, @venue.attributes.merge(:title => "SpaceCube"))
    post.size.should == pre.size
  end

  it "should find duplicate for matching multiple fields" do
    pre, post = find_duplicates_create_a_clone_and_find_again([:title, :address], {:title => @venue.title, :address => @venue.address})
    post.size.should == pre.size + 2
  end

  it "should not find duplicates for mismatching multiple fields" do
    pre, post = find_duplicates_create_a_clone_and_find_again([:title, :address], {:title => "SpaceCube", :address => @venue.address})
    post.size.should == pre.size
  end
end

describe Venue, "when checking for squashing" do
  before(:all) do
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
    @slave_first.progenitor.should == @master
  end

  it "should return the progenitor of a grandchild" do
    @slave_second.progenitor.should == @master
  end
  
  it "should return a master as its own progenitor" do
    @master.progenitor.should == @master
  end
  
  it "should return the progenitor if an imported venue has an exact duplicate" do
    @abstract_location = SourceParser::AbstractLocation.new
    @abstract_location.title = @slave_second.title

    Venue.from_abstract_location(@abstract_location).should == @master
  end
  
end

describe Venue, "when squashing duplicates" do
  before(:each) do
    Venue.destroy_all
    Event.destroy_all

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

    @submaster_venue.duplicate_of.should == @master_venue
    @submaster_venue.duplicate?.should be_true
  end

  it "should squash multiple duplicates" do
    Venue.squash(:master => @master_venue, :duplicates => [@submaster_venue, @child_venue])

    @submaster_venue.duplicate_of.should == @master_venue
    @child_venue.duplicate_of.should == @master_venue
  end

  it "should squash duplicates recursively" do
    Venue.squash(:master => @master_venue, :duplicates => @submaster_venue)

    @submaster_venue.duplicate_of.should == @master_venue
    @child_venue.reload # Needed because child was queried through DB, not object graph
    @child_venue.duplicate_of.should == @master_venue
  end

  it "should transfer events of duplicates" do
    @venues.map{|venue| venue.events.count}.should == [0, 1, 1]

    Venue.squash(:master => @master_venue, :duplicates => @submaster_venue)

    @venues.map(&:reload)
    @venues.map{|venue| venue.events.count}.should == [2, 0, 0]

    events = @venues.map(&:events).flatten
    events.size.should > 0
    for event in events
      event.venue.should == @master_venue
    end
  end

  it "should squash duplicates by ID" do
    Venue.squash(:master => @master_venue.id, :duplicates => @submaster_venue.id)

    @submaster_venue.reload
    @master_venue.reload
    @submaster_venue.duplicate_of.should == @master_venue
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
    @venue.valid?.should == true
  end

  it "should report its location properly if it has one" do
    lambda {
      @venue.latitude = 45.0
      @venue.longitude = -122.0
    }.should change { @venue.location }.from(nil).to([BigDecimal("45.0"), BigDecimal("-122.0")])
  end

  it "should geocode automatically on save" do
    GeoKit::Geocoders::MultiGeocoder.should_receive(:geocode).once.and_return(@geo_success)
    @venue.save
  end

  it "shouldn't geocode automatically unless there's an address" do
    @venue.address = ""
    GeoKit::Geocoders::MultiGeocoder.should_not_receive(:geocode)
    @venue.save
  end

  it "shouldn't geocode automatically if already geocoded" do
    @venue.latitude = @venue.longitude = 0.0
    GeoKit::Geocoders::MultiGeocoder.should_not_receive(:geocode)
    @venue.save
  end

  it "shouldn't fail if the geocoder returns failure" do
    GeoKit::Geocoders::MultiGeocoder.should_receive(:geocode).once.and_return(@geo_failure)
    @venue.save
  end

  it "should fill in empty addressing fields" do
    GeoKit::Geocoders::MultiGeocoder.should_receive(:geocode).once.and_return(@geo_success)
    @venue.save
    @venue.street_address.should == @geo_success.street_address
    @venue.locality.should == @geo_success.city
    @venue.region.should == @geo_success.state
    @venue.postal_code.should == @geo_success.zip
  end

  it "should leave non-empty addressing fields alone" do
    @venue.locality = "Cleveland"
    GeoKit::Geocoders::MultiGeocoder.should_receive(:geocode).once.and_return(@geo_success)
    @venue.save
    @venue.locality.should == "Cleveland"
  end

  it "should strip location when geocoding is forced" do
    @venue.force_geocoding=true
    @venue.latitude.should==nil
    @venue.longitude.should==nil
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
    @venue.geocode_address.should == "street_address, locality region postal_code country"
  end

  it "should fall back to 'address' field if street address fields are blank" do
    @venue.attributes = {:street_address => "", :address => "address"}
    @venue.geocode_address.should == "address"
  end
  
  describe "acting as versioned" do
    it "should have versions" do
      Venue.new.versions.should==[]
    end
    
    it "should increment the version number when editing" do
      venue = Venue.create!(:title => 'My Event')
      venue.version.should==1
      
      venue.title = "New Title"
      venue.save!
      venue.version.should==2
    end
  end
end
