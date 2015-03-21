# We're extending ActsAsTaggableOn's Tag model to include support for machine tags and such.
module TagModelExtensions
  def self.included(base)
    base.class_eval do
      scope :machine_tags, where("name LIKE '%:%=%'")
    end
  end

  #---[ Machine tags ]----------------------------------------------------

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
  MACHINE_TAG_PATTERN = /([^:]+):([^=]+)=(.+)/ unless defined?(MACHINE_TAG_PATTERN)

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
  def machine_tag
    if components = self.name.match(MACHINE_TAG_PATTERN)
      namespace, predicate, value = components.captures

      result = {
        :namespace => namespace,
        :predicate => predicate,
        :value     => value,
      }

      if machine_tag = MACHINE_TAG_URLS[namespace]
        if url_template = machine_tag[predicate]
          result[:url] = sprintf(url_template, value)
          if namespace =~ /\A(upcoming|gowalla|shizzow)\Z/
            domain = "http://localhost:3000" if Rails.env.development? || Rails.env.test?
            domain = "http://calagator.org" if Rails.env.production?
            archive_date = Event.tagged_with(self).first.start_time.strftime("%Y%m%d") if Event.tagged_with(self).first
            archive_date = Venue.tagged_with(self).first.created_at.strftime("%Y%m%d") if Venue.tagged_with(self).first
            result[:url] = "#{domain}/defunct?url=https://web.archive.org/web/#{archive_date}/#{result[:url]}"
          end
        end
      end

      return result
    else
      return {}
    end
  end
end

