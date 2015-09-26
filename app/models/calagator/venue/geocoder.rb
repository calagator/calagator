module Calagator

class Venue < ActiveRecord::Base
  class Geocoder < Struct.new(:venue)
    cattr_accessor(:perform_geocoding) { true }

    def self.geocode(venue)
      new(venue).geocode
    end

    def geocode
      return unless should_geocode?
      map_geo_to_venue if geo.success
      log
    end

    private

    def geo
      @geo ||= Geokit::Geocoders::MultiGeocoder.geocode(venue.geocode_address)
    end

    VENUE_GEO_FIELD_MAP = {
      street_address: :street_address,
      locality:       :city,
      region:         :state,
      postal_code:    :zip,
      country:        :country_code,
    }

    def map_geo_to_venue
      # always overwrite lat and long
      venue.latitude = geo.lat
      venue.longitude = geo.lng

      VENUE_GEO_FIELD_MAP.each do |venue_field, geo_field|
        next if venue[venue_field].present?
        venue[venue_field] = geo.send(geo_field)
      end
    end

    def should_geocode?
      [
        perform_geocoding,
        (venue.location.blank? || venue.force_geocoding == "1"),
        venue.geocode_address.present?,
        venue.duplicate_of.blank?
      ].all?
    end

    def log
      venue_id = venue.new_record? ? "new record" : "record #{venue.id}"
      status = geo.success ? "was successful" : "failed"
      message = "Venue#add_geocoding for #{venue} #{status}, response was: #{geo.inspect}"
      Rails.logger.info message
    end
  end
end

end
