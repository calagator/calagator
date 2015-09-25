require 'spec_helper'

module Calagator

describe Calagator::Source::Parser::Ical::VenueParser, "when parsing VVENUE", :type => :model do
   subject do
     described_class.new(<<-ICAL).to_venue
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
ICAL
  end

  it "should have a street_address" do
    expect(subject.street_address).not_to be_nil
  end

  it "should have the adress as is" do
    expect(subject.street_address).to eq '700 Southwest Fifth Avenue Suite #1035'
  end

  it "should have a locality" do
    expect(subject.locality).not_to be_nil
  end

  it "should have the locality as is" do
    expect(subject.locality).to eq 'Portland'
  end
end

describe Source::Parser::Ical::VenueParser, "when parsing VCARD lines", :type => :model do
   before(:each) do
     # Note that each line here represents a single, complete property definition -- this method doesn't do any magical unwrapping of text.
     @vcard_hash = described_class.new.send :hash_from_vcard_lines, %(
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
CATEGORIES:apple applecom appleinc technology).split("\n")
  end

  it "should find a property set by its key" do
    expect(@vcard_hash['NAME']).to eq 'Apple Store Pioneer Place'
  end

  it "should find a property set by its key and meta-qualifier by its key when one wasn't specified" do
    expect(@vcard_hash['URL']).to eq 'http://eventful.com/V0-001-001423875-1'
  end

  it "should find a property set by its key and multiple meta-qualifiers by its key when one wasn't specified" do
    expect(@vcard_hash['COUNTRY']).to eq 'United States'
  end

  it "should find a property set by its key and meta-qualifier with odd characters by its key when one wasn't specified" do
    expect(@vcard_hash['REGION']).to eq 'Oregon'
  end
end

end
