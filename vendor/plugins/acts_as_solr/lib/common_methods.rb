module ActsAsSolr #:nodoc:
  
  module CommonMethods
    
    # Converts field types into Solr types
    def get_solr_field_type(field_type)
      if field_type.is_a?(Symbol)
        case field_type
          when :float:          return "f"
          when :integer:        return "i"
          when :boolean:        return "b"
          when :string:         return "s"
          when :date:           return "d"
          when :range_float:    return "rf"
          when :range_integer:  return "ri"
          when :facet:          return "facet"
          when :text:           return "t"
        else
          raise "Unknown field_type symbol: #{field_type}"
        end
      elsif field_type.is_a?(String)
        return field_type
      else
        raise "Unknown field_type class: #{field_type.class}: #{field_type}"
      end
    end
    
    # Sets a default value when value being set is nil.
    def set_value_if_nil(field_type)
      case field_type
        when "b", :boolean:                        return "false"
        when "s", "t", "d", :date, :string, :text: return ""
        when "f", "rf", :float, :range_float:      return 0.00
        when "i", "ri", :integer, :range_integer:  return 0
      else
        return ""
      end
    end
    
    # Sends an add command to Solr
    def solr_add(add_xml)
      ActsAsSolr::Post.execute(Solr::Request::AddDocument.new(add_xml))
    end
    
    # Sends the delete command to Solr
    def solr_delete(solr_ids)
      ActsAsSolr::Post.execute(Solr::Request::Delete.new(:id => solr_ids))
    end
    
    # Sends the commit command to Solr
    def solr_commit
      ActsAsSolr::Post.execute(Solr::Request::Commit.new)
    end
    
    # Optimizes the Solr index. Solr says:
    # 
    # Optimizations can take nearly ten minutes to run. 
    # We are presuming optimizations should be run once following large 
    # batch-like updates to the collection and/or once a day.
    # 
    # One of the solutions for this would be to create a cron job that 
    # runs every day at midnight and optmizes the index:
    #   0 0 * * * /your_rails_dir/script/runner -e production "Model.solr_optimize"
    # 
    def solr_optimize
      ActsAsSolr::Post.execute(Solr::Request::Optimize.new)
    end
    
    # Returns the id for the given instance
    def record_id(object)
      eval "object.#{object.class.primary_key}"
    end
    
  end
  
end