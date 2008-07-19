module ActsAsSolr #:nodoc:
  
  class Post
    def initialize(body, mode = :search)
      @body = body
      @mode = mode
      puts "The method ActsAsSolr::Post.new(body, mode).execute_post is depracated. " +
           "Use ActsAsSolr::Post.execute(body, mode) instead!"
    end
    
    def execute_post
      ActsAsSolr::Post.execute(@body, @mode)
    end    
  end
  
  module ClassMethods
    def find_with_facet(query, options={})
      Deprecation.plog "The method find_with_facet is deprecated. Use find_by_solr instead, passing the " +
                       "arguments the same way you used to do with find_with_facet."
      find_by_solr(query, options)
    end
  end
  
  class Deprecation
    # Validates the options passed during query
    def self.validate_query options={}
      if options[:field_types]
        plog "The option :field_types for searching is deprecated. " +
             "The field types are automatically traced back when you specify a field type in your model."
      end
      if options[:sort_by]
        plog "The option :sort_by is deprecated, use :order instead!"
        options[:order] ||= options[:sort_by]
      end
      if options[:start]
        plog "The option :start is deprecated, use :offset instead!"
        options[:offset] ||= options[:start]
      end
      if options[:rows]
        plog "The option :rows is deprecated, use :limit instead!"
        options[:limit] ||= options[:rows]
      end
    end
    
    # Validates the options passed during indexing
    def self.validate_index options={}
      if options[:background]
        plog "The :background option is being deprecated. There are better and more efficient " +
             "ways to handle delayed saving of your records."
      end
    end
    
    # This will print the text to stdout and log the text
    # if rails logger is available
    def self.plog text
      puts text
      RAILS_DEFAULT_LOGGER.warn text if defined? RAILS_DEFAULT_LOGGER
    end
  end
  
end
