# We're extending ActsAsTaggableOn's Tag model to include support for machine tags and such.
module Calagator

class MachineTag < Struct.new(:name)
  module TagExtensions
    def machine_tag
      MachineTag.new(name).to_hash
    end
  end

  # Structure of machine tag namespaces and predicates to their URLs. See
  # #machine_tag for details.
  MACHINE_TAG_URLS = {
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
  } unless defined?(MACHINE_TAG_URLS)

  # Regular expression for parsing machine tags
  MACHINE_TAG_PATTERN = /(?<namespace>[^:]+):(?<predicate>[^=]+)=(?<value>.+)/ unless defined?(MACHINE_TAG_PATTERN)

  # Machine tag predicates that refer to place entries
  VENUE_PREDICATES = %w(venue place spot biz) unless defined?(VENUE_PREDICATES)

  # Return a machine tag hash for this tag, or an empty hash if this isn't a
  # machine tag. The hash will always contain :namespace, :predicate and :value
  # key-value pairs. It may also contain an :url if one is known.
  #
  # Machine tags describe references to remote resources. For example, a
  # Calagator event imported from an Meetup event may have a machine
  # linking it back to the Meetup event.
  #
  # Example:
  #   # A tag named "meetup:group=1234" will produce this machine tag:
  #   tag.machine_tag == {
  #     :namespace => "meetup",
  #     :predicate => "group",
  #     :value     => "1234",
  #     :url       => "http://www.meetup.com/1234",
  def to_hash
    return {} unless matches
    {
      namespace: namespace,
      predicate: predicate,
      value:     value,
      url:       url,
    }
  end

  def venue?
    VENUE_PREDICATES.include? predicate
  end

  private

  def matches
    name.match(MACHINE_TAG_PATTERN)
  end

  def namespace
    matches[:namespace]
  end

  def predicate
    matches[:predicate]
  end

  def value
    matches[:value]
  end

  def url
    return unless machine_tag = MACHINE_TAG_URLS[namespace]
    return unless url_template = machine_tag[predicate]
    url = sprintf(url_template, value)
    url = "#{site_root_url}defunct?url=https://web.archive.org/web/#{archive_date}/#{url}" if defunct?
    url
  end

  def defunct?
    %w(upcoming gowalla shizzow).include? namespace
  end

  def archive_date
    (venue_date || event_date).strftime("%Y%m%d")
  end

  def venue_date
    Venue.tagged_with(name).limit(1).pluck(:created_at).first
  end

  def event_date
    Event.tagged_with(name).limit(1).pluck(:start_time).first
  end

  def site_root_url
    Calagator.url
  end
end

end
