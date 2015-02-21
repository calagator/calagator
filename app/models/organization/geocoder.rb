class Organization < ActiveRecord::Base
  class Geocoder < Struct.new(:organization, :geo)
    cattr_accessor(:perform_geocoding) { true }
    class << self
      alias_method :perform_geocoding?, :perform_geocoding
    end

    def self.geocode(organization)
      new(organization).geocode
    end

    def geocode
      return true unless should_geocode?

      self.geo = GeoKit::Geocoders::MultiGeocoder.geocode(organization.geocode_address)
      if geo.success
        organization.latitude       = geo.lat
        organization.longitude      = geo.lng
        organization.street_address = geo.street_address if organization.street_address.blank?
        organization.locality       = geo.city           if organization.locality.blank?
        organization.region         = geo.state          if organization.region.blank?
        organization.postal_code    = geo.zip            if organization.postal_code.blank?
        organization.country        = geo.country_code   if organization.country.blank?
      end

      log
    end

    private

    def should_geocode?
      [
        self.class.perform_geocoding?,
        (organization.location.blank? || organization.force_geocoding == "1"),
        organization.geocode_address.present?,
        organization.duplicate_of.blank?
      ].all?
    end

    def log
      organization_id = organization.new_record? ? "new record" : "record #{organization.id}"
      status = geo.success ? "was successful" : "failed"
      message = "Organization#add_geocoding for #{organization} #{status}, response was: #{geo.inspect}"
      Rails.logger.info message
    end
  end
end
