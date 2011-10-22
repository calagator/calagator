# We're extending ActsAsTaggableOn's Tag model to include support for machine tags and such.
module TagModelExtensions
  def self.included(base)
    base.extend ClassMethods
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
  # Calagator event imported from an Upcoming event may have a machine
  # linking it back to the Upcoming event.
  #
  # Example:
  #   # A tag named "upcoming:event=1234" will produce this machine tag:
  #   tag.machine_tag == {
  #     :namespace => "upcoming",
  #     :predicate => "event",
  #     :value     => "1234",
  #     :url       => "http://upcoming.yahoo.com/event/1234",
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
        end
      end

      return result
    else
      return {}
    end
  end

  module ClassMethods
    # TODO: Look at replacing this with the built-in acts_as_taggable_on tag cloud stuff
    #       See https://github.com/mbleigh/acts-as-taggable-on for details.
    #
    # Return data structure that can be used to make a tag cloud.
    #
    # Argument:
    # * type: The ActiveRecord model class to find tags for.
    # * minimum_taggings: The minimum number of taggings that a tag must have to be included in the results.
    # * levels: The number of levels that the tag cloud has.
    #
    # The data structure is an array of hashes representing tags sorted by name, each hash has:
    # * :tag => The tag model instance.
    # * :count => The count of matching taggings for this tag.
    # * :level => The tag cloud level, the higher the count, the higher the level.
    def for_tagcloud(type=Event, minimum_taggings=20, levels=5)
      exclusions = SETTINGS.tagcloud_exclusions || ['']
      counts_and_tags = []
      benchmark("Tag::for_tagcloud") do
        for tag in ActsAsTaggableOn::Tag.find_by_sql ['SELECT tags.name, COUNT(taggings.id) AS counter FROM tags, taggings WHERE tags.id = taggings.tag_id AND taggings.taggable_type = ? AND tags.name NOT IN (?) GROUP BY tags.name HAVING COUNT(taggings.id) > ? ORDER BY LOWER(tags.name) ASC', type.name, exclusions, minimum_taggings]
          count = tag.counter.to_i
          counts_and_tags << [count, tag]
        end
      end

      max_count = counts_and_tags.map(&:first).max.to_f
      return counts_and_tags.map do |count, tag|
        {:tag => tag, :count => count, :level => ((count / max_count) * (levels - 1)).round}
      end
    end
  end
end

