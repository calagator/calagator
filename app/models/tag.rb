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
  MACHINE_TAG_URLS = {
    'upcoming' => {
      'event' => "http://upcoming.yahoo.com/event/[value]",
      'venue' => "http://upcoming.yahoo.com/venue/[value]"
    },
    'plancast' => {
      'activity' => "http://plancast.com/a/[value]"
    },
    'yelp' => {
      'biz' => "http://www.yelp.com/biz/[value]"
    },
    'foursquare' => {
      'venue' => "http://foursquare.com/venue/[value]"
    },
    'gowalla' => {
      'spot' => "http://gowalla.com/spots/[value]"
    },
    'shizzow' => {
      'place' => "http://www.shizzow.com/places/[value]"
    }
  }


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

    def machine_tag
      machine_tag = {}
      if components = self.name.match(/([^:]+):([^=]+)=(.+)/)
        namespace, predicate, value = components.captures
        url = MACHINE_TAG_URLS[namespace].try(:[], predicate).try(:gsub, '[value]', value)

        machine_tag = { :namespace => namespace,
                        :predicate => predicate,
                        :value => value,
                        :url => url }
      end

      machine_tag
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
      tags_and_counts = []
      benchmark("Tag::for_tagcloud") do
        for tag in Tag.find_by_sql ['SELECT tags.name, count(taggings.id) as counter FROM tags, taggings WHERE tags.id = taggings.tag_id AND taggings.taggable_type = ? GROUP BY taggings.tag_id HAVING counter > ? ORDER BY lower(tags.name) asc', type.name, minimum_taggings]
          next if %w[ostartupskey tvg].include?(tag.name)
          count = tag.counter.to_i
          tags_and_counts << [tag, count]
        end
      end

      max_count = tags_and_counts.sort_by(&:last).last.last.to_f
      return tags_and_counts.map do |tag, count|
          {:tag => tag, :count => count, :level => ((count / max_count) * (levels - 1)).round}
      end
    end

    # Tag::Error class. Raised by ActiveRecord::Base::TaggingExtensions if something goes wrong.
    class Error < StandardError
    end
  end
end
