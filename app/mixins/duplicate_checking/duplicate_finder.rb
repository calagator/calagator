module DuplicateChecking
  class DuplicateFinder < Struct.new(:model, :fields, :options)
    def find
      query = "SELECT DISTINCT a.* FROM #{model.table_name} a, #{model.table_name} b WHERE"
      query << " #{options[:where]} AND " if options[:where]
      query << " a.id <> b.id AND ("

      if fields == :all
        query << query_from_all
      elsif fields == :any
        query << query_from_any
      else
        query << query_from_fields
      end

      query << ")"

      records = model.find_by_sql(query) || []

      # Reject known duplicates
      records.reject!(&:duplicate_of_id)

      if grouped
        matched_fields = lambda {|r| fields.map {|f| r.read_attribute(f.to_sym) }} if Array === fields
        # Group by the field values we're matching on; skip any values for which we only have one record
        records = records.group_by { |record| matched_fields.call(record) if matched_fields }
        records.reject! { |value, group| group.size <= 1 }
      end
      records
    end

    def fields
      super || :all
    end

    private

    def grouped
      options[:grouped] || false
    end

    def query_from_all
      attributes.map do |attr|
        "((a.#{attr} = b.#{attr}) OR (a.#{attr} IS NULL AND b.#{attr} IS NULL))"
      end.join(" AND ")
    end

    def query_from_any
      attributes.map do |attr|
        query = "(a.#{attr} = b.#{attr} AND ("
        column = model.columns.find {|column| column.name.to_sym == attr}
        case column.type
        when :integer, :decimal
          query << "a.#{attr} != 0 AND "
        when :string, :text
          query << "a.#{attr} != '' AND "
        end
        query << "a.#{attr} IS NOT NULL))"
      end.join(" OR ")
    end

    def query_from_fields
      raise ArgumentError, "Unknown fields: #{fields.inspect}" if (Array(fields) - attributes).any?
      Array(fields).map do |attr|
        "a.#{attr} = b.#{attr}"
      end.join(" AND ")
    end

    def attributes
      # TODO make find_duplicates_by(:all) pay attention to ignore fields
      model.new.attribute_names.map(&:to_sym).reject do |attr|
        [:id, :created_at, :updated_at, :duplicate_of_id, :version].include?(attr)
      end
    end
  end
end
