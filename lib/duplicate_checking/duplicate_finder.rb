module DuplicateChecking
  class DuplicateFinder < Struct.new(:model, :fields, :options)
    def find
      scope = model.select("a.*")
      scope = scope.from("#{model.table_name} a, #{model.table_name} b")
      scope = scope.where(options[:where]) if options[:where]
      scope = scope.where("a.id <> b.id")
      scope = scope.where("a.duplicate_of_id" => nil)
      scope = scope.where(query)
      scope.distinct

      records = scope.all
      records = group_by_fields(records) if grouped
      records
    end

    def fields
      super || :all
    end

    private

    def query
      case fields
        when :all then query_from_all
        when :any then query_from_any
        else query_from_fields
      end
    end

    def grouped
      options[:grouped] || false
    end

    def group_by_fields records
      # Group by the field values we're matching on; skip any values for which we only have one record
      records = records.group_by do |record|
        fields.map do |field|
          record.read_attribute(field)
        end
      end
      records.reject { |value, group| group.size <= 1 }
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
