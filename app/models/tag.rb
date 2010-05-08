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
      'event' => "http://upcoming.yahoo.com/event/[value]"
    },
    'plancast' => {
      'activity' => "http://plancast.com/a/[value]"
    }
  }


  if (table_exists? rescue nil)
    DELIMITER = "," # Controls how to split and join tagnames from strings. You may need to change the <tt>validates_format_of parameters</tt> if you change this.

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

    # Tag::Error class. Raised by ActiveRecord::Base::TaggingExtensions if something goes wrong.
    class Error < StandardError
    end
  end
end
