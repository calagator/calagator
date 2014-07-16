module DuplicateChecking
  class DuplicateFinder < Struct.new(:model, :fields, :options)
    def find
      fields = self.fields # seriously, WTF! apparently there is ALREADY a fields local variable?? ruby bug???
      grouped = options[:grouped] || false
      selections = ['a.*', options[:select]].compact.join(', ')
      froms = ["#{model.table_name} a", "#{model.table_name} b", options[:from]].compact.join(', ')
      froms << " #{options[:joins]}" if options[:joins]
      query = "SELECT DISTINCT #{selections} from #{froms} WHERE"
      query << " #{options[:where]} AND " if options[:where]
      query << " a.id <> b.id AND ("
      attributes = model.new.attribute_names
      matched_fields = nil

      if fields.nil? || (fields.respond_to?(:blank?) && fields.blank?)
        fields = :all
      end

      if fields == :all || fields == :any
        matched = false
        attributes.each do |attr|
          # TODO make find_duplicates_by(:all) pay attention to ignore fields
          next if ['id','created_at','updated_at', 'duplicate_of_id','version'].include?(attr)
          if fields == :all
            query << " AND" if matched
            query << " ((a.#{attr} = b.#{attr}) OR (a.#{attr} IS NULL AND b.#{attr} IS NULL))"
          else
            query << " OR" if matched
            query << " (a.#{attr} = b.#{attr} AND ("
            column = model.columns.find {|column| column.name == attr}
            case column.type
            when :integer, :decimal
              query << "a.#{attr} != 0 AND "
            when :string, :text
              query << "a.#{attr} != '' AND "
            end
            query << "a.#{attr} IS NOT NULL))"
          end
          matched = true
        end
      else
        matched = false
        fields = [fields].flatten
        fields.each do |attr|
          if attributes.include?(attr.to_s)
            query << " AND" if matched
            query << " a.#{attr} = b.#{attr}"
            matched = true
          else
            raise ArgumentError, "Unknow fields: #{fields.inspect}"
          end
        end
        matched_fields = lambda {|r| fields.map {|f| r.read_attribute(f.to_sym) }}
      end

      query << " )"

      Rails.logger.debug("find_duplicates_by: SQL -- #{query}")
      records = model.find_by_sql(query) || []

      # Reject known duplicates
      records.reject! {|t| t.duplicate_of_id} if records.first.respond_to?(:duplicate_of_id)

      if grouped
        # Group by the field values we're matching on; skip any values for which we only have one record
        records.group_by { |record| matched_fields.call(record) if matched_fields }\
               .reject { |value, group| group.size <= 1 }
      else
        records
      end
    end
  end
end
