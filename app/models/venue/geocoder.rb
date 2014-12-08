class Venue < ActiveRecord::Base
  class Geocoder < Struct.new(:venue, :geo)
    cattr_accessor(:perform_geocoding) { true }
    class << self
      alias_method :perform_geocoding?, :perform_geocoding
    end

    def self.geocode(venue)
      new(venue).geocode
    end

    def geocode
      return true unless should_geocode?

      self.geo = GeoKit::Geocoders::MultiGeocoder.geocode(venue.geocode_address)
      if geo.success
        venue.latitude       = geo.lat
        venue.longitude      = geo.lng
        venue.street_address = geo.street_address if venue.street_address.blank?
        venue.locality       = geo.city           if venue.locality.blank?
        venue.region         = geo.state          if venue.region.blank?
        venue.postal_code    = geo.zip            if venue.postal_code.blank?
        venue.country        = geo.country_code   if venue.country.blank?
      end

      log
    end

    private

    def should_geocode?
      [
        self.class.perform_geocoding?,
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
