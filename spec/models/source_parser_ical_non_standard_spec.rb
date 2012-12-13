require 'spec_helper'

describe SourceParser::Ical, "when parsing VVENUE" do
   before(:each) do
     @location = SourceParser::Ical.to_abstract_location(<<-HERE)
BEGIN:VVENUE
X-VVENUE-INFO:http://evdb.com/docs/ical-venue/draft-norris-ical-venue.
  html
UID:V0-001-001423875-1@eventful.com
NAME:Apple Store Pioneer Place
DESCRIPTION:(503) 222-3002 Driving Directions & Map  Store Hours:  Mon
   - Fri: 9:30 a.m. to 9:00 p.m. Sat: 9:30 a.m. to 8:00 p.m. Sun: 11:00
  a.m. to 6:00 p.m.
ADDRESS:700 Southwest Fifth Avenue Suite #1035
CITY:Portland
REGION;ABBREV=OR:Oregon
COUNTRY;ABBREV=USA:United States
POSTALCODE:97204
GEO:45.518798;-122.677583
URL;X-LABEL=Venue Info:http://eventful.com/V0-001-001423875-1
CATEGORIES:apple applecom appleinc technology
END:VVENUE
    HERE
  end

  it "should have a street_address" do
    @location.street_address.should_not be_nil
  end

  it "should have the adress as is" do
    @location.street_address == '700 Southwest Fifth Avenue Suite #1035'
  end

  it "should have a locality" do
    @location.locality.should_not be_nil
  end

  it "should have the locality as is" do
    @location.locality == 'Portland'
  end
end

describe SourceParser::Ical, "when parsing VCARD lines" do
   before(:each) do
     # Note that each line here represents a single, complete property definition -- this method doesn't do any magical unwrapping of text.
     @vcard_hash = SourceParser::Ical.hash_from_vcard_lines(<<-HERE)
X-VVENUE-INFO:http://evdb.com/docs/ical-venue/draft-norris-ical-venue.html
UID:V0-001-001423875-1@eventful.com
NAME:Apple Store Pioneer Place
DESCRIPTION:(503) 222-3002 Driving Directions & Map  Store Hours:  Mon - Fri: 9:30 a.m. to 9:00 p.m. Sat: 9:30 a.m. to 8:00 p.m. Sun: 11:00 a.m. to 6:00 p.m.
ADDRESS:700 Southwest Fifth Avenue Suite; #1035
CITY:Portland
REGION;KMeta=none&bizzare:Oregon
COUNTRY;;;ABBREV=USA:United States
POSTALCODE:97204
GEO:45.518798;-122.677583
URL;X-LABEL=Venue Info:http://eventful.com/V0-001-001423875-1
CATEGORIES:apple applecom appleinc technology
    HERE
  end

  it "should find a property set by its key" do
    @vcard_hash['NAME'].should == 'Apple Store Pioneer Place'
  end

  it "should find a property set by its key and meta-qualifier" do
    @vcard_hash['URL;X-LABEL=Venue Info'].should == 'http://eventful.com/V0-001-001423875-1'
  end

  it "should find a property set by its key and meta-qualifier by its key when one wasn't specified" do
    @vcard_hash['URL'].should == 'http://eventful.com/V0-001-001423875-1'
  end

  it "should find a property set by its key and multiple meta-qualifier by" do
    @vcard_hash['COUNTRY;;;ABBREV=USA'] == 'United States'
  end

  it "should find a property set by its key and multiple meta-qualifiers by its key when one wasn't specified" do
    @vcard_hash['COUNTRY'] == 'United States'
  end

  it "should find a property set by its key and meta-qualifier with odd characters" do
    @vcard_hash['REGION;KMeta=none&bizzare'] == 'Oregon'
  end

  it "should find a property set by its key and meta-qualifier with odd characters by its key when one wasn't specified" do
    @vcard_hash['REGION'] == 'Oregon'
  end
end
