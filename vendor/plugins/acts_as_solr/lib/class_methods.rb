require File.dirname(__FILE__) + '/common_methods'
require File.dirname(__FILE__) + '/parser_methods'

module ActsAsSolr #:nodoc:

  module ClassMethods
    include CommonMethods
    include ParserMethods
    
    # Finds instances of a model. Terms are ANDed by default, can be overwritten 
    # by using OR between terms
    # 
    # Here's a sample (untested) code for your controller:
    # 
    #  def search
    #    results = Book.find_by_solr params[:query]
    #  end
    # 
    # You can also search for specific fields by searching for 'field:value'
    # 
    # ====options:
    # offset:: - The first document to be retrieved (offset)
    # limit:: - The number of rows per page
    # order:: - Orders (sort by) the result set using a given criteria:
    #
    #             Book.find_by_solr 'ruby', :order => 'description asc'
    # 
    # field_types:: This option is deprecated and will be obsolete by version 1.0.
    #               There's no need to specify the :field_types anymore when doing a 
    #               search in a model that specifies a field type for a field. The field 
    #               types are automatically traced back when they're included.
    # 
    #                 class Electronic < ActiveRecord::Base
    #                   acts_as_solr :fields => [{:price => :range_float}]
    #                 end
    # 
    # facets:: This option argument accepts the following arguments:
    #          fields:: The fields to be included in the faceted search (Solr's facet.field)
    #          query:: The queries to be included in the faceted search (Solr's facet.query)
    #          zeros:: Display facets with count of zero. (true|false)
    #          sort:: Sorts the faceted resuls by highest to lowest count. (true|false)
    #          browse:: This is where the 'drill-down' of the facets work. Accepts an array of
    #                   fields in the format "facet_field:term"
    # 
    # Example:
    # 
    #   Electronic.find_by_solr "memory", :facets => {:zeros => false, :sort => true,
    #                                                 :query => ["price:[* TO 200]",
    #                                                            "price:[200 TO 500]",
    #                                                            "price:[500 TO *]"],
    #                                                 :fields => [:category, :manufacturer],
    #                                                 :browse => ["category:Memory","manufacturer:Someone"]}
    # 
    # scores:: If set to true this will return the score as a 'solr_score' attribute
    #          for each one of the instances found. Does not currently work with find_id_by_solr
    # 
    #            books = Book.find_by_solr 'ruby OR splinter', :scores => true
    #            books.records.first.solr_score
    #            => 1.21321397
    #            books.records.last.solr_score
    #            => 0.12321548
    # 
    def find_by_solr(query, options={})
      data = parse_query(query, options)
      return parse_results(data, options) if data
    end
    
    # Finds instances of a model and returns an array with the ids:
    #  Book.find_id_by_solr "rails" => [1,4,7]
    # The options accepted are the same as find_by_solr
    # 
    def find_id_by_solr(query, options={})
      data = parse_query(query, options)
      return parse_results(data, {:format => :ids}) if data
    end
    
    # This method can be used to execute a search across multiple models:
    #   Book.multi_solr_search "Napoleon OR Tom", :models => [Movie]
    # 
    # ====options:
    # Accepts the same options as find_by_solr plus:
    # models:: The additional models you'd like to include in the search
    # results_format:: Specify the format of the results found
    #                  :objects :: Will return an array with the results being objects (default). Example:
    #                               Book.multi_solr_search "Napoleon OR Tom", :models => [Movie], :results_format => :objects
    #                  :ids :: Will return an array with the ids of each entry found. Example:
    #                           Book.multi_solr_search "Napoleon OR Tom", :models => [Movie], :results_format => :ids
    #                           => [{"id" => "Movie:1"},{"id" => Book:1}]
    #                          Where the value of each array is as Model:instance_id
    # 
    def multi_solr_search(query, options = {})
      models = "AND (#{solr_configuration[:type_field]}:#{self.name}"
      options[:models].each{|m| models << " OR type_t:"+m.to_s} if options[:models].is_a?(Array)
      options.update(:results_format => :objects) unless options[:results_format]
      data = parse_query(query, options, models<<")")
      result = []
      if data
        docs = data.docs
        return SearchResults.new(:docs => [], :total => 0) if data.total == 0
        if options[:results_format] == :objects
          docs.each{|doc| k = doc.fetch('id').to_s.split(':'); result << k[0].constantize.find_by_id(k[1])}
        elsif options[:results_format] == :ids
          docs.each{|doc| result << {"id"=>doc.values.pop.to_s}}
        end
        SearchResults.new :docs => result, :total => data.total
      end
    end
    
    # returns the total number of documents found in the query specified:
    #  Book.count_by_solr 'rails' => 3
    # 
    def count_by_solr(query, options = {})        
      data = parse_query(query, options)
      data.total_hits
    end
            
    # It's used to rebuild the Solr index for a specific model. 
    #  Book.rebuild_solr_index
    # 
    # If batch_size is greater than 0, adds will be done in batches.
    # NOTE: If using sqlserver, be sure to use a finder with an explicit order.
    # Non-edge versions of rails do not handle pagination correctly for sqlserver
    # without an order clause.
    # 
    # If a finder block is given, it will be called to retrieve the items to index.
    # This can be very useful for things such as updating based on conditions or
    # using eager loading for indexed associations.
    def rebuild_solr_index(batch_size=0, &finder)
      finder ||= lambda { |ar, options| ar.find(:all, options.merge({:order => self.primary_key})) }
    
      if batch_size > 0
        items_processed = 0
        limit = batch_size
        offset = 0
        begin
          items = finder.call(self, {:limit => limit, :offset => offset})
          add_batch = items.collect { |content| content.to_solr_doc }
    
          if items.size > 0
            solr_add add_batch
            solr_commit
          end
    
          items_processed += items.size
          logger.debug "#{items_processed} items for #{self.name} have been batch added to index."
          offset += items.size
        end while items.nil? || items.size > 0
      else
        items = finder.call(self, {})
        items.each { |content| content.solr_save }
        items_processed = items.size
      end
      solr_optimize
      logger.debug items_processed > 0 ? "Index for #{self.name} has been rebuilt" : "Nothing to index for #{self.name}"
    end
  end
  
end