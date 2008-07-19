module ActsAsSolr #:nodoc:
  
  module InstanceMethods

    # Solr id is <class.name>:<id> to be unique across all models
    def solr_id
      "#{self.class.name}:#{record_id(self)}"
    end

    # saves to the Solr index
    def solr_save
      return true unless configuration[:if] 
      if evaluate_condition(configuration[:if], self) 
        logger.debug "solr_save: #{self.class.name} : #{record_id(self)}"
        solr_add to_solr_doc
        solr_commit if configuration[:auto_commit]
        true
      else
        solr_destroy
      end
    end

    # remove from index
    def solr_destroy
      logger.debug "solr_destroy: #{self.class.name} : #{record_id(self)}"
      solr_delete solr_id
      solr_commit if configuration[:auto_commit]
      true
    end

    # convert instance to Solr document
    def to_solr_doc
      logger.debug "to_solr_doc: creating doc for class: #{self.class.name}, id: #{record_id(self)}"
      doc = Solr::Document.new
      doc.boost = validate_boost(configuration[:boost]) if configuration[:boost]
      
      doc << {:id => solr_id,
              solr_configuration[:type_field] => self.class.name,
              solr_configuration[:primary_key_field] => record_id(self).to_s}

      # iterate through the fields and add them to the document,
      configuration[:solr_fields].each do |field|
        field_name = field
        field_type = configuration[:facets] && configuration[:facets].include?(field) ? :facet : :text
        field_boost= solr_configuration[:default_boost]

        if field.is_a?(Hash)
          field_name = field.keys.pop
          if field.values.pop.respond_to?(:each_pair)
            attributes = field.values.pop
            field_type = get_solr_field_type(attributes[:type]) if attributes[:type]
            field_boost= attributes[:boost] if attributes[:boost]
          else
            field_type = get_solr_field_type(field.values.pop)
            field_boost= field[:boost] if field[:boost]
          end
        end
        value = self.send("#{field_name}_for_solr")
        value = set_value_if_nil(field_type) if value.to_s == ""
        
        # add the field to the document, but only if it's not the id field
        # or the type field (from single table inheritance), since these
        # fields have already been added above.
        if field_name.to_s != self.class.primary_key and field_name.to_s != "type"
          suffix = get_solr_field_type(field_type)
          # This next line ensures that e.g. nil dates are excluded from the 
          # document, since they choke Solr. Also ignores e.g. empty strings, 
          # but these can't be searched for anyway: 
          # http://www.mail-archive.com/solr-dev@lucene.apache.org/msg05423.html
          next if value.nil? || value.to_s.strip.empty?
          [value].flatten.each do |v|
            v = set_value_if_nil(suffix) if value.to_s == ""
            field = Solr::Field.new("#{field_name}_#{suffix}" => ERB::Util.html_escape(v.to_s))
            field.boost = validate_boost(field_boost)
            doc << field
          end
        end
      end
      
      add_includes(doc) if configuration[:include]
      logger.debug doc.to_xml.to_s
      return doc
    end
    
    private
    def add_includes(doc)
      if configuration[:include].is_a?(Array)
        configuration[:include].each do |association|
          data = ""
          klass = association.to_s.singularize
          case self.class.reflect_on_association(association).macro
          when :has_many, :has_and_belongs_to_many
            records = self.send(association).to_a
            unless records.empty?
              records.each{|r| data << r.attributes.inject([]){|k,v| k << "#{v.first}=#{ERB::Util.html_escape(v.last)}"}.join(" ")}
              doc["#{klass}_t"] = data
            end
          when :has_one, :belongs_to
            record = self.send(association)
            unless record.nil?
              data = record.attributes.inject([]){|k,v| k << "#{v.first}=#{ERB::Util.html_escape(v.last)}"}.join(" ")
              doc["#{klass}_t"] = data
            end
          end
        end
      end
    end
    
    def validate_boost(boost)
      if boost.class != Float || boost < 0
        logger.warn "The boost value has to be a float and posisive, but got #{boost}. Using default boost value."
        return solr_configuration[:default_boost]
      end
      boost
    end
    
    def condition_block?(condition)
      condition.respond_to?("call") && (condition.arity == 1 || condition.arity == -1)
    end
    
    def evaluate_condition(condition, field)
      case condition
        when Symbol: field.send(condition)
        when String: eval(condition, binding)
        else
          if condition_block?(condition)
            condition.call(field)
          else
            raise(
              ArgumentError,
              "The :if option has to be either a symbol, string (to be eval'ed), proc/method, or " +
              "class implementing a static validation method"
            )
          end
        end
    end
    
  end
end