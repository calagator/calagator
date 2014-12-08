class Venue < ActiveRecord::Base
  class Geocoder < Struct.new(:venue)
    def self.geocode(venue)
      new(venue).geocode
    end

    def geocode
      if Venue.perform_geocoding? && venue.location.blank? && venue.geocode_address.present? && venue.duplicate_of.blank?
        geo = GeoKit::Geocoders::MultiGeocoder.geocode(venue.geocode_address)
        if geo.success
          venue.latitude       = geo.lat
          venue.longitude      = geo.lng
          venue.street_address = geo.street_address if venue.street_address.blank?
          venue.locality       = geo.city           if venue.locality.blank?
          venue.region         = geo.state          if venue.region.blank?
          venue.postal_code    = geo.zip            if venue.postal_code.blank?
          venue.country        = geo.country_code   if venue.country.blank?
        end

        msg = 'Venue#add_geocoding for ' + (venue.new_record? ? 'new record' : "record #{venue.id}") + ' ' + (geo.success ? 'was successful' : 'failed') + ', response was: ' + geo.inspect
        Rails.logger.info(msg)
      end

      return true
    end
  end
end
