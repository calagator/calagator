require File.dirname(__FILE__) + '/../spec_helper'

describe Venue, "with hCalendar to AbstractEvent parsing" do
  it "should extract an AbstractEvent from an hCalendar text" do
    hcal_upcoming = read_sample('hcal_upcoming.xml')

    SourceParser::Hcal.stub!(:read_url).and_return(hcal_upcoming)
    abstract_events = SourceParser::Hcal.to_abstract_events(:url => "http://foo.bar/")
    abstract_event = abstract_events.first
    abstract_location = abstract_event.location

    abstract_location.should be_a_kind_of(SourceParser::AbstractLocation)
    abstract_location.locality.should =~ /portland/i
    abstract_location.street_address.should =~ /317 SW Alder St Ste 500/i
    abstract_location.latitude.should_not be_nil
    abstract_location.longitude.should_not be_nil
  end
end

describe Venue, "with duplicate finder" do
  it "should find all venues with duplicate titles" do
    Venue.should_receive(:find_by_sql).with("SELECT DISTINCT a.* from venues a, venues b WHERE a.id <> b.id AND ( a.title = b.title ) ORDER BY a.title")
    Venue.find(:duplicates, :by => :title )
  end

  it "should find all venues with duplicate titles and urls" do
    Venue.should_receive(:find_by_sql).with("SELECT DISTINCT a.* from venues a, venues b WHERE a.id <> b.id AND ( a.title = b.title AND a.url = b.url ) ORDER BY a.title,a.url")
    Venue.find(:duplicates, :by => [:title,:url])
  end

  it "should find all venues that have not been marked as duplicate" do
    Venue.should_receive(:find_without_duplicate_support).with(:all, :conditions => "duplicate_of_id IS NULL")
    Venue.find(:non_duplicates)
  end

  it "should find all venues that have been marked as duplicate" do
    Venue.should_receive(:find_without_duplicate_support).with(:all, :conditions => "duplicate_of_id IS NOT NULL")
    Venue.find(:marked_duplicates)
  end
end

describe Venue, "with duplicate finder (integration)" do
  fixtures :venues

  before(:each) do
    @venue = venues(:cubespace)
  end

  def compare_duplicates(find_duplicates_arguments, create_venue_attributes)
    before_results = Venue.find(:duplicates, :by => find_duplicates_arguments)
    venue = Venue.new(create_venue_attributes)
    venue.stub!(:geocode)
    venue.save!
    after_results = Venue.find(:duplicates, :by => find_duplicates_arguments)
    return [before_results.sort_by(&:created_at), after_results.sort_by(&:created_at)]
  end

  it "should find duplicate title by title" do
    pre, post = compare_duplicates(:title, :title => @venue.title)
    post.size.should == pre.size + 2
  end

  it "should find duplicate title by any" do
    pre, post = compare_duplicates(:any, :title => @venue.title)
    post.size.should == pre.size + 2
  end

  it "should not find duplicate title by address" do
    pre, post = compare_duplicates(:address, :title => @venue.title)
    post.size.should == pre.size
  end

  it "should find complete duplicates by all" do
    pre, post = compare_duplicates(:all, @venue.attributes)
    pending "find_duplicates_by(:all) seems to be failing because of null handling"
    post.size.should == pre.size + 2
  end

  it "should not find incomplete duplicates by all" do
    pre, post = compare_duplicates(:all, @venue.attributes.merge(:title => "SpaceCube"))
    post.size.should == pre.size
  end

  it "should find duplicate for matching multiple fields" do
    pre, post = compare_duplicates([:title, :address], {:title => @venue.title, :address => @venue.address})
    post.size.should == pre.size + 2
  end

  it "should not find duplicates for mismatching multiple fields" do
    pre, post = compare_duplicates([:title, :address], {:title => "SpaceCube", :address => @venue.address})
    post.size.should == pre.size
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
    @geo_success = mock("geo", :success => true, :lat => 0.0, :lng => 0.0)
    @geo_failure = mock("geo", :success => false, :lat => nil, :lng => nil)
  end

  it "should be valid even if not yet geocoded" do
    @venue.valid?.should == true
  end
  
  it "should properly report whether it has a location already" do
    lambda {
      @venue.latitude = @venue.longitude = 0.0
    }.should change { @venue.has_location? }.from(false).to(true)
  end

  it "should geocode automatically" do
    GeoKit::Geocoders::MultiGeocoder.should_receive(:geocode).once.and_return(@geo_success)
    @venue.save
  end
  
  it "shouldn't geocode unless there's an address" do
    @venue.address = ""
    GeoKit::Geocoders::MultiGeocoder.should_not_receive(:geocode)
    @venue.save
  end
    
  it "shouldn't geocode if already geocoded" do
    @venue.latitude = @venue.longitude = 0.0
    GeoKit::Geocoders::MultiGeocoder.should_not_receive(:geocode)
    @venue.save
  end
    
  it "shouldn't fail if the address is completely bogus" do
    @venue.address = "lsdfjsdfxouisodfglkjwerid"
    GeoKit::Geocoders::MultiGeocoder.should_receive(:geocode).once.and_return(@geo_failure)
    @venue.save
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
end
