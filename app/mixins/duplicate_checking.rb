module DuplicateChecking
  def self.included(base)
    base.class_eval do
      extend ClassMethods
    end
  end
  
  module ClassMethods
    # Return an array of events with duplicate values for a given set of fields
    def find_duplicates_by(fields)
      query = "SELECT DISTINCT a.* from #{table_name} a, #{table_name} b WHERE a.id <> b.id AND ("
      attributes = new.attribute_names
    
      if fields == :all || fields == :any
        attributes.each do |attr|
          next if ['id','created_at','updated_at'].include?(attr)
          if fields == :all
            query += " a.#{attr} = b.#{attr} AND"
          else
            query += " (a.#{attr} = b.#{attr} AND (a.#{attr} != '' AND a.#{attr} != 0 AND a.#{attr} NOT NULL)) OR "
          end
        end
      else
        fields = [fields].flatten
        fields.each do |attr|
            query += " a.#{attr} = b.#{attr} AND" if attributes.include?(attr.to_s)
        end
        order = fields.join(',a.')
      end
      order ||= 'id'
      query = query[0..-4] + ") ORDER BY a.#{order}"
      find_by_sql(query)
    end
  end
end