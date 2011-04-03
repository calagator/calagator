# == Schema Information
# Schema version: 20080705164959
#
# Table name: tags
#
#  id   :integer         not null, primary key
#  name :string(255)     not null
#


# The Tag model. This model is automatically generated and added to your app if you run the tagging generator included with has_many_polymorphs.

class Tag < ActiveRecord::Base
  if (table_exists? rescue nil)
    DELIMITER = "," # Controls how to split and join tagnames from strings. You may need to change the <tt>validates_format_of parameters</tt> if you change this.

    has_many :taggings

    # If database speed becomes an issue, you could remove these validations and rescue the ActiveRecord database constraint errors instead.
    validates_presence_of :name
    validates_uniqueness_of :name, :case_sensitive => false
  
    # Change this validation if you need more complex tag names.
    validates_format_of :name,
      :with => %r{^[^#{Tag::DELIMITER}]+$},
      :message => "can not contain delimiter character: #{Tag::DELIMITER}"
  
    # Set up the polymorphic relationship.
    begin
      has_many_polymorphs :taggables, 
        :from => [:events, :venues, :sources], 
        :through => :taggings, 
        :dependent => :destroy,
        :skip_duplicates => false, 
        :parent_extend => proc {
          # Defined on the taggable models, not on Tag itself. Return the tagnames associated with this record as a string.
          def to_s
            self.map(&:name).sort.join("#{Tag::DELIMITER} ")
          end
        }
    rescue NoMethodError => e
      raise e unless $rails_gem_installer
    end
    
    # Callback to strip extra spaces from the tagname before saving it. If you allow tags to be renamed later, you might want to use the <tt>before_save</tt> callback instead.
  
    def before_create 
      self.name = name.downcase.strip.squeeze(" ")
    end

    # Tag::Error class. Raised by ActiveRecord::Base::TaggingExtensions if something goes wrong.
    class Error < StandardError
    end
  end

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
  def self.for_tagcloud(type=Event, minimum_taggings=20, levels=5)
    exclusions = SETTINGS.tagcloud_exclusions || ['']
    counts_and_tags = []
    benchmark("Tag::for_tagcloud") do
      for tag in Tag.find_by_sql ['SELECT tags.name, count(taggings.id) as counter FROM tags, taggings WHERE tags.id = taggings.tag_id AND taggings.taggable_type = ? AND tags.name NOT IN (?) GROUP BY taggings.tag_id HAVING counter > ? ORDER BY lower(tags.name) asc', type.name, exclusions, minimum_taggings]
        count = tag.counter.to_i
        counts_and_tags << [count, tag]
      end
    end

    max_count = counts_and_tags.map(&:first).max.to_f
    return counts_and_tags.map do |count, tag|
        {:tag => tag, :count => count, :level => ((count / max_count) * (levels - 1)).round}
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
    }
  }

  # Regular expression for parsing machine tags
  MACHINE_TAG_PATTERN = /([^:]+):([^=]+)=(.+)/

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
end
