require 'geokit'

# CALAGATOR: Differences from the defaults are tagged like this below.

# remap Google V3 geocoder so we can reference it in provider list, see:
# https://github.com/geokit/geokit/issues/86
Geokit::Geocoders::Google3Geocoder = Geokit::Geocoders::GoogleGeocoder3

# These defaults are used in GeoKit::Mappable.distance_to and in acts_as_mappable
GeoKit::default_units = :miles
GeoKit::default_formula = :sphere

# This is the timeout value in seconds to be used for calls to the geocoder web
# services.  For no timeout at all, comment out the setting.  The timeout unit
# is in seconds. 
GeoKit::Geocoders::request_timeout = 3

# These settings are used if web service calls must be routed through a proxy.
# These setting can be nil if not needed, otherwise, addr and port must be 
# filled in at a minimum.  If the proxy requires authentication, the username
# and password can be provided as well.
GeoKit::Geocoders::proxy_addr = nil
GeoKit::Geocoders::proxy_port = nil
GeoKit::Geocoders::proxy_user = nil
GeoKit::Geocoders::proxy_pass = nil

# This is your yahoo application key for the Yahoo Geocoder.
# See http://developer.yahoo.com/faq/index.html#appid
# and http://developer.yahoo.com/maps/rest/V1/geocode.html
GeoKit::Geocoders::yahoo = 'REPLACE_WITH_YOUR_YAHOO_KEY'
    
# This is your Google Maps geocoder key. 
# See http://www.google.com/apis/maps/signup.html
# and http://www.google.com/apis/maps/documentation/#Geocoding_Examples
#
# CALAGATOR: was GeoKit::Geocoders::google = 'REPLACE_WITH_YOUR_GOOGLE_KEY',
# but since each developer needs their own, we get it from an (optional)
# separate file.
#
# CALAGATOR: We also assign the key to GOOGLE_APPLICATION_ID to make
# the gmaps_on_rails plugin happy.
#
keys_path = Rails.root.join('config','geocoder_api_keys.yml')
if File.exist? keys_path
  geocoder_api_keys = YAML.load_file(keys_path)
  GeoKit::Geocoders::google = GOOGLE_APPLICATION_ID = \
    geocoder_api_keys.fetch(Rails.env,{})['google']
end

# This is your username and password for geocoder.us.
# To use the free service, the value can be set to nil or false.  For 
# usage tied to an account, the value should be set to username:password.
# See http://geocoder.us
# and http://geocoder.us/user/signup
GeoKit::Geocoders::geocoder_us = false 

# This is your authorization key for geocoder.ca.
# To use the free service, the value can be set to nil or false.  For 
# usage tied to an account, set the value to the key obtained from
# Geocoder.ca.
# See http://geocoder.ca
# and http://geocoder.ca/?register=1
GeoKit::Geocoders::geocoder_ca = false

# This is the order in which the geocoders are called in a failover scenario
# If you only want to use a single geocoder, put a single symbol in the array.
# Valid symbols are :google, :yahoo, :us, and :ca.
# Be aware that there are Terms of Use restrictions on how you can use the 
# various geocoders.  Make sure you read up on relevant Terms of Use for each
# geocoder you are going to use.
#
# CALAGATOR: was [:google, :us], but this is all we need since we're Google-only.
#
GeoKit::Geocoders::provider_order = [:google3]
