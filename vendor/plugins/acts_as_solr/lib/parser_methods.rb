module ActsAsSolr #:nodoc:
  
  module ParserMethods
    
    protected    
    
    # Method used by mostly all the ClassMethods when doing a search
    def parse_query(query=nil, options={}, models=nil)
      valid_options = [:offset, :limit, :facets, :models, :results_format, :order, :scores, :operator]
      query_options = {}
      return if query.nil?
      raise "Invalid parameters: #{(options.keys - valid_options).join(',')}" unless (options.keys - valid_options).empty?
      begin
        Deprecation.validate_query(options)
        query_options[:start] = options[:offset]
        query_options[:rows] = options[:limit]
        query_options[:operator] = options[:operator]
        
        # first steps on the facet parameter processing
        if options[:facets]
          query_options[:facets] = {}
          query_options[:facets][:limit] = -1  # TODO: make this configurable
          query_options[:facets][:sort] = :count if options[:facets][:sort]
          query_options[:facets][:mincount] = 0
          query_options[:facets][:mincount] = 1 if options[:facets][:zeros] == false
          query_options[:facets][:fields] = options[:facets][:fields].collect{|k| "#{k}_facet"} if options[:facets][:fields]
          query_options[:filter_queries] = replace_types(options[:facets][:browse].collect{|k| "#{k.sub!(/ *: */,"_facet:")}"}) if options[:facets][:browse]
          query_options[:facets][:queries] = replace_types(options[:facets][:query].collect{|k| "#{k.sub!(/ *: */,"_t:")}"}) if options[:facets][:query]
        end
        
        if models.nil?
          # TODO: use a filter query for type, allowing Solr to cache it individually
          models = "AND #{solr_configuration[:type_field]}:#{self.name}"
          field_list = solr_configuration[:primary_key_field]
        else
          field_list = "id"
        end
        
        query_options[:field_list] = [field_list, 'score']
        query = "(#{query.gsub(/ *: */,"_t:")}) #{models}"
        order = options[:order].split(/\s*,\s*/).collect{|e| e.gsub(/\s+/,'_t ').gsub(/\bscore_t\b/, 'score')  }.join(',') if options[:order] 
        query_options[:query] = replace_types([query])[0] # TODO adjust replace_types to work with String or Array  

        if options[:order]
          # TODO: set the sort parameter instead of the old ;order. style.
          query_options[:query] << ';' << replace_types([order], false)[0]
        end
               
        ActsAsSolr::Post.execute(Solr::Request::Standard.new(query_options))
      rescue
        raise "There was a problem executing your search: #{$!}"
      end            
    end
    
    # Parses the data returned from Solr
    def parse_results(solr_data, options = {})
      results = {
        :docs => [],
        :total => 0
      }
      configuration = {
        :format => :objects
      }
      results.update(:facets => {'facet_fields' => []}) if options[:facets]
      return SearchResults.new(results) if solr_data.total == 0
      
      configuration.update(options) if options.is_a?(Hash)

      ids = solr_data.docs.collect {|doc| doc["#{solr_configuration[:primary_key_field]}"]}.flatten
      conditions = [ "#{self.table_name}.#{primary_key} in (?)", ids ]
      result = configuration[:format] == :objects ? reorder(self.find(:all, :conditions => conditions), ids) : ids
      add_scores(result, solr_data) if configuration[:format] == :objects && options[:scores]
      
      results.update(:facets => solr_data.data['facet_counts']) if options[:facets]
      results.update({:docs => result, :total => solr_data.total, :max_score => solr_data.max_score})
      SearchResults.new(results)
    end
    
    # Reorders the instances keeping the order returned from Solr
    def reorder(things, ids)
      ordered_things = []
      ids.each do |id|
        record = things.find {|thing| record_id(thing).to_s == id.to_s} 
        raise "Out of sync! The id #{id} is in the Solr index but missing in the database!" unless record
        ordered_things << record
      end
      ordered_things
    end

    # Replaces the field types based on the types (if any) specified
    # on the acts_as_solr call
    def replace_types(strings, include_colon=true)
      suffix = include_colon ? ":" : ""
      if configuration[:solr_fields] && configuration[:solr_fields].is_a?(Array)
        configuration[:solr_fields].each do |solr_field|
          field_type = get_solr_field_type(:text)
          if solr_field.is_a?(Hash)
            solr_field.each do |name,value|
         	    if value.respond_to?(:each_pair)
                field_type = get_solr_field_type(value[:type]) if value[:type]
              else
                field_type = get_solr_field_type(value)
              end
              field = "#{name.to_s}_#{field_type}#{suffix}"
              strings.each_with_index {|s,i| strings[i] = s.gsub(/#{name.to_s}_t#{suffix}/,field) }
            end
          end
        end
      end
      strings
    end
    
    # Adds the score to each one of the instances found
    def add_scores(results, solr_data)
      with_score = []
      solr_data.docs.each do |doc|
        with_score.push([doc["score"], 
          results.find {|record| record_id(record).to_s == doc["#{solr_configuration[:primary_key_field]}"].to_s }])
      end
      with_score.each do |score,object| 
        class <<object; attr_accessor :solr_score; end
        object.solr_score = score
      end
    end
  end

end