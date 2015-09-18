module Calagator

module DuplicateChecking
  class DuplicateFinder < Struct.new(:model, :fields)
    def find
      scope = model.select("#{model.table_name}.*")
      scope.from!("#{model.table_name}, #{model.table_name} b")
      scope.where!("#{model.table_name}.id <> b.id")
      scope.where!("#{model.table_name}.duplicate_of_id" => nil)
      scope.where!(query)
      scope.distinct!

      scope = yield(scope) if block_given?

      group_by_fields(scope.to_a)
    end

    def fields
      super.map(&:to_sym)
    end

    private

    def query
      case fields
        when [:all] then query_from_all
        when [:any] then query_from_any
        else query_from_fields
      end
    end

    def group_by_fields records
      # Group by the field values we're matching on; skip any values for which we only have one record
      records = records.group_by do |record|
        Array(fields).map do |field|
          record.read_attribute(field)
        end
      end
      records.reject { |value, group| group.size <= 1 }
    end

    def query_from_all
      attributes.map do |attr|
        "((#{model.table_name}.#{attr} = b.#{attr}) OR (#{model.table_name}.#{attr} IS NULL AND b.#{attr} IS NULL))"
      end.join(" AND ")
    end

    def query_from_any
      attributes.map do |attr|
        query = "(#{model.table_name}.#{attr} = b.#{attr} AND ("
        column = model.columns.find {|column| column.name.to_sym == attr}
        case column.type
        when :integer, :decimal
          query << "#{model.table_name}.#{attr} != 0 AND "
        when :string, :text
          query << "#{model.table_name}.#{attr} != '' AND "
        end
        query << "#{model.table_name}.#{attr} IS NOT NULL))"
      end.join(" OR ")
    end

    def query_from_fields
      raise ArgumentError, "Unknown fields: #{fields.inspect}" if (Array(fields) - attributes).any?
      Array(fields).map do |attr|
        "#{model.table_name}.#{attr} = b.#{attr}"
      end.join(" AND ")
    end

    def attributes
      # TODO make :all pay attention to ignore fields
      model.new.attribute_names.map(&:to_sym).reject do |attr|
        [:id, :created_at, :updated_at, :duplicate_of_id, :version].include?(attr)
      end
    end
  end
end

end
