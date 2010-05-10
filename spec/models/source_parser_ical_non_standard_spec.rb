require File.dirname(__FILE__) + '/../spec_helper'

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
COUNTRY;ABBREV=USA:United: States
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
  #etcetera: the above cases work sufficiently
end


# While implementing this rspec I noted that the RiCal parser does nothing more than strip
# the BEGIN and END tags off of VVENUE items
# I'd like to discuss whether or not we write a module that does a better job of handling VVENUE
# gracefully than RiCal does, and with less wheel spinning?
# it works as is but....

describe SourceParser::Ical, "when munging vcard_lines" do

   before(:each) do
   @vcard_hash = SourceParser::Ical.v_card_munge(<<-HERE)
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
    HERE

  end
  
  it "should" do
    
  end

end

