# frozen_string_literal: true

require 'spec_helper'

module Calagator
  describe Venue, type: :model do
    it 'is valid' do
      venue = described_class.new(title: 'My Event')
      expect(venue).to be_valid
    end

    it 'adds an http prefix to urls missing this before save' do
      venue = described_class.new(title: 'My Event', url: 'google.com')
      expect(venue).to be_valid
    end

    it 'validates blacklisted words' do
      BlacklistValidator.any_instance.stub(patterns: [/\bcialis\b/, /\bviagra\b/])
      venue = described_class.new(title: 'Foo bar cialis')
      expect(venue).not_to be_valid
    end

    describe 'latitude validation' do
      specify do
        venue = described_class.new(latitude: -91)
        expect(venue).to have(1).error_on(:latitude)
      end

      specify do
        venue = described_class.new(latitude: -89)
        expect(venue).to have(0).errors_on(:latitude)
      end
    end

    describe 'longitude validation' do
      specify do
        venue = described_class.new(longitude: -181)
        expect(venue).to have(1).error_on(:longitude)
      end

      specify do
        venue = described_class.new(longitude: -179)
        expect(venue).to have(0).errors_on(:longitude)
      end
    end

    describe 'when validating' do
      let(:attributes) { { title: 'My Venue' } }
      let(:bad_data) { ' blargie ' }
      let(:expected_data) { bad_data.strip }

      %i[title description address street_address locality region postal_code country email telephone].each do |field|
        it "strips whitespace from #{field}" do
          venue = described_class.new(attributes.merge(field => bad_data))
          venue.valid?
          expect(venue.send(field)).to eq(expected_data)
        end
      end

      it 'strips whitespace from url' do
        venue = described_class.new(attributes.merge(url: bad_data))
        venue.valid?
        expect(venue.url).to eq("http://#{expected_data}")
      end
    end

    describe 'when finding exact duplicates' do
      it 'ignores attributes like created_at' do
        venue1 = described_class.create!(title: 'this', description: 'desc', created_at: Time.now.in_time_zone)
        venue2 = described_class.new(title: 'this', description: 'desc', created_at: Time.now.in_time_zone.yesterday)

        expect(venue2.find_exact_duplicates).to include(venue1)
      end

      it 'ignores source_id' do
        venue1 = described_class.create!(title: 'this', description: 'desc', source_id: '1')
        venue2 = described_class.new(title: 'this', description: 'desc', source_id: '2')

        expect(venue2.find_exact_duplicates).to include(venue1)
      end

      it 'does not match non-duplicates' do
        described_class.create!(title: 'this', description: 'desc')
        venue2 = described_class.new(title: 'that', description: 'desc')

        expect(venue2.find_exact_duplicates).to be_blank
      end
    end

    describe 'when finding duplicates [integration test]' do
      subject! do
        FactoryBot.create(:venue, title: 'Venue A')
      end

      it 'does not match totally different records' do
        FactoryBot.create(:venue)
        expect(described_class.find_duplicates_by_type('title')).to be_empty
      end

      it 'does not match similar records when not searching by duplicated fields' do
        FactoryBot.create :venue, title: subject.title
        expect(described_class.find_duplicates_by_type('description')).to be_empty
      end

      it 'matches similar records when searching by duplicated fields' do
        venue = FactoryBot.create(:venue, title: subject.title)
        expect(described_class.find_duplicates_by_type('title')).to eq([subject.title] => [subject, venue])
      end

      it 'matches similar records when searching by :any' do
        venue = FactoryBot.create(:venue, title: subject.title)
        expect(described_class.find_duplicates_by_type('any')).to eq([nil] => [subject, venue])
      end

      it 'does not match similar records when searching by multiple fields where not all are duplicated' do
        FactoryBot.create(:venue, title: subject.title)
        expect(described_class.find_duplicates_by_type('title,description')).to be_empty
      end

      it 'matches similar records when searching by multiple fields where all are duplicated' do
        venue = FactoryBot.create(:venue, title: subject.title, description: subject.description)
        expect(described_class.find_duplicates_by_type('title,description')).to \
          eq([subject.title, subject.description] => [subject, venue])
      end

      it 'does not match dissimilar records when searching by :all' do
        FactoryBot.create(:venue)
        expect(described_class.find_duplicates_by_type('all')).to be_empty
      end

      it 'matches similar records when searching by :all' do
        attributes = subject.attributes.reject { |key| key == 'id' }
        venue = described_class.create!(attributes)
        expect(described_class.find_duplicates_by_type('all')).to eq([nil] => [subject, venue])
      end

      it 'matches non duplicate venues when searching by na' do
        venue = FactoryBot.create(:venue, title: 'Venue B')
        expect(described_class.find_duplicates_by_type('na')).to eq([nil] => [subject, venue])
      end
    end

    describe 'when checking for squashing' do
      before do
        @master = described_class.create!(title: 'Master')
        @slave_first = described_class.create!(title: '1st slave', duplicate_of_id: @master.id)
        @slave_second = described_class.create!(title: '2nd slave', duplicate_of_id: @slave_first.id)
      end

      it 'recognizes a master' do
        expect(@master).to be_a_master
      end

      it 'recognizes a slave' do
        expect(@slave_first).to be_a_slave
      end

      it 'does not think that a slave is a master' do
        expect(@slave_second).not_to be_a_master
      end

      it 'does not think that a master is a slave' do
        expect(@master).not_to be_a_slave
      end

      it 'returns the progenitor of a child' do
        expect(@slave_first.progenitor).to eq @master
      end

      it 'returns the progenitor of a grandchild' do
        expect(@slave_second.progenitor).to eq @master
      end

      it 'returns a master as its own progenitor' do
        expect(@master.progenitor).to eq @master
      end
    end

    describe 'when squashing duplicates' do
      before do
        @master_venue    = described_class.create!(title: 'Master')
        @submaster_venue = described_class.create!(title: 'Submaster')
        @child_venue     = described_class.create!(title: 'Child', duplicate_of: @submaster_venue)
        @venues          = [@master_venue, @submaster_venue, @child_venue]

        @event_at_child_venue = Event.create!(title: 'Event at child venue', venue: @child_venue, start_time: Time.now.in_time_zone)
        @event_at_submaster_venue = Event.create!(title: 'Event at submaster venue', venue: @submaster_venue, start_time: Time.now.in_time_zone)
        @events = [@event_at_child_venue, @event_at_submaster_venue]
      end

      it 'squashes a single duplicate' do
        described_class.squash(@master_venue, @submaster_venue)

        expect(@submaster_venue.duplicate_of).to eq @master_venue
        expect(@submaster_venue).to be_duplicate
      end

      it 'squashes multiple duplicates' do
        described_class.squash(@master_venue, [@submaster_venue, @child_venue])

        expect(@submaster_venue.duplicate_of).to eq @master_venue
        expect(@child_venue.duplicate_of).to eq @master_venue
      end

      it 'squashes duplicates recursively' do
        described_class.squash(@master_venue, @submaster_venue)

        expect(@submaster_venue.duplicate_of).to eq @master_venue
        @child_venue.reload # Needed because child was queried through DB, not object graph
        expect(@child_venue.duplicate_of).to eq @master_venue
      end

      it 'transfers events of duplicates' do
        expect(@venues.map { |venue| venue.events.count }).to eq [0, 1, 1]

        described_class.squash(@master_venue, @submaster_venue)

        expect(@venues.map { |venue| venue.events.count }).to eq [2, 0, 0]

        events = @venues.flat_map(&:events).each(&:reload)
        expect(events.map(&:venue)).to all(eq @master_venue)
      end
    end
  end

  describe 'Venue geocoding', type: :model do
    before do
      @venue = Venue.new(title: 'title', address: 'test')
      @geo_failure = double('geo', success: false)
      @geo_success = double('geo', success: true, lat: 0.0, lng: 0.0,
                                   street_address: '622 SE Grand Ave.', city: 'Portland',
                                   state: 'OR', country_code: '', zip: '97214')
      @geocodable_address = "#{@geo_success.street_address}, #{@geo_success.city}" \
                            "#{@geo_success.state} #{@geo_success.zip}"
    end

    it 'is valid even if not yet geocoded' do
      expect(@venue).to be_valid
    end

    it 'reports its location properly if it has one' do
      expect do
        @venue.latitude = 45.0
        @venue.longitude = -122.0
      end.to change { @venue.location }.from(false).to([BigDecimal('45.0'), BigDecimal('-122.0')])
    end

    describe 'with geocoding' do
      # Enable geocoding for just these tests
      around do |example|
        original = Venue::Geocoder.perform_geocoding
        Venue::Geocoder.perform_geocoding = true
        example.run
        Venue::Geocoder.perform_geocoding = original
      end

      it 'geocodes automatically on save' do
        expect(Geokit::Geocoders::MultiGeocoder).to receive(:geocode).once.and_return(@geo_success)
        @venue.save
      end

      it "does not geocode automatically unless there's an address" do
        @venue.address = ''
        expect(Geokit::Geocoders::MultiGeocoder).not_to receive(:geocode)
        @venue.save
      end

      it 'does not geocode automatically if already geocoded' do
        @venue.latitude = @venue.longitude = 0.0
        expect(Geokit::Geocoders::MultiGeocoder).not_to receive(:geocode)
        @venue.save
      end

      it 'does not fail if the geocoder returns failure' do
        expect(Geokit::Geocoders::MultiGeocoder).to receive(:geocode).once.and_return(@geo_failure)
        @venue.save
      end

      it 'fills in empty addressing fields' do
        expect(Geokit::Geocoders::MultiGeocoder).to receive(:geocode).once.and_return(@geo_success)
        @venue.save
        expect(@venue.street_address).to eq @geo_success.street_address
        expect(@venue.locality).to eq @geo_success.city
        expect(@venue.region).to eq @geo_success.state
        expect(@venue.postal_code).to eq @geo_success.zip
      end

      it 'leaves non-empty addressing fields alone' do
        @venue.locality = 'Cleveland'
        expect(Geokit::Geocoders::MultiGeocoder).to receive(:geocode).once.and_return(@geo_success)
        @venue.save
        expect(@venue.locality).to eq 'Cleveland'
      end

      it 'does not overwrite present fields with empty values' do
        @venue.country = 'US'
        expect(Geokit::Geocoders::MultiGeocoder).to receive(:geocode).once.and_return(@geo_success)
        @venue.save
        expect(@venue.country).to eq 'US'
      end

      it 'overwrites latitude and longitude values if forced' do
        @venue.latitude = @venue.longitude = 1.0
        @venue.force_geocoding = '1'
        expect(Geokit::Geocoders::MultiGeocoder).to receive(:geocode).once.and_return(@geo_success)
        @venue.save
        expect(@venue.latitude).to eq 0.0
        expect(@venue.longitude).to eq 0.0
      end
    end
  end

  describe 'Venue geocode addressing', type: :model do
    before do
      @venue = Venue.new(title: 'title')
    end

    it "uses the street address fields if they're present" do
      @venue.attributes = {
        street_address: 'street_address',
        locality: 'locality',
        region: 'region',
        postal_code: 'postal_code',
        country: 'country',
        address: 'address'
      }
      expect(@venue.geocode_address).to eq 'street_address, locality region postal_code country'
    end

    it "falls back to 'address' field if street address fields are blank" do
      @venue.attributes = { street_address: '', address: 'address' }
      expect(@venue.geocode_address).to eq 'address'
    end

    describe 'when versioning' do
      it 'has versions' do
        expect(Venue.new.versions).to eq []
      end

      it 'creates a new version after updating' do
        venue = FactoryBot.create :venue
        expect(venue.versions.count).to eq 1

        venue.title += ' (change)'

        venue.save!
        expect(venue.versions.count).to eq 2
      end

      it 'stores old content in past versions' do
        venue = FactoryBot.create :venue
        original_title = venue.title

        venue.title += ' (change)'

        venue.save!
        expect(venue.versions.last.reify.title).to eq original_title
      end
    end
  end
end
