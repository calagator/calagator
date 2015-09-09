require "acts-as-taggable-on"
require "calagator/machine_tag"
ActsAsTaggableOn::Tag.send :include, Calagator::MachineTag::TagExtensions

# Structure of machine tag namespaces and predicates to their URLs. See
# Calagator::MachineTag for details.
Calagator::MachineTag.configure do |config|
  config.urls.merge! \
    'epdx' => {
      'company' => 'http://epdx.org/companies/%s',
      'group' => 'http://epdx.org/groups/%s',
      'person' => 'http://epdx.org/people/%s',
      'project' => 'http://epdx.org/projects/%s',
    },
    'upcoming' => {
      'event' => "http://upcoming.yahoo.com/event/%s",
      'venue' => "http://upcoming.yahoo.com/venue/%s"
    },
      'plancast' => {
      'activity' => "http://plancast.com/a/%s",
      'plan' => "http://plancast.com/p/%s"
    },
      'yelp' => {
      'biz' => "http://www.yelp.com/biz/%s"
    },
      'foursquare' => {
      'venue' => "http://foursquare.com/venue/%s"
    },
      'gowalla' => {
      'spot' => "http://gowalla.com/spots/%s"
    },
      'shizzow' => {
      'place' => "http://www.shizzow.com/places/%s"
    },
      'meetup' => {
      'group' => "http://www.meetup.com/%s"
    },
      'facebook' => {
      'event' => "http://www.facebook.com/event.php?eid=%s"
    },
      'lanyrd' => {
      'event' => "http://lanyrd.com/%s"
    }

  config.venue_predicates = %w(venue place spot biz)

  config.defunct_namespaces = %w(upcoming gowalla shizzow)

  config.site_root_url = Calagator.url
end

