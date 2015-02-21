class Organization < ActiveRecord::Base
  class SearchEngine
    class Sql < Struct.new(:query, :opts)
      def self.search(*args)
        new(*args).search
      end

      def search
        base.keywords.non_duplicates.order.limit.scope.to_a
      end

      protected

      attr_accessor :scope

      def base
        column_names = Organization.column_names.map { |name| "organizations.#{name}" }
        @scope = Organization.scoped
          .group(column_names)
          .joins("LEFT OUTER JOIN taggings on taggings.taggable_id = organizations.id AND taggings.taggable_type = 'Organization'")
          .joins("LEFT OUTER JOIN tags ON tags.id = taggings.tag_id")
        self
      end

      def keywords
        query_conditions = @scope
          .where(['LOWER(title) LIKE ?', "%#{query.downcase}%"])
          .where(['LOWER(description) LIKE ?', "%#{query.downcase}%"])

        query_conditions = query.split.inject(query_conditions) do |query_conditions, keyword|
          query_conditions.where(['LOWER(tags.name) = ?', keyword])
        end

        @scope = @scope.where(query_conditions.where_values.join(' OR '))
        self
      end

      def non_duplicates
        @scope = @scope.non_duplicates
        self
      end

      def order
        @scope = @scope.order('LOWER(organizations.title) ASC')
        self
      end

      def limit
        @scope = @scope.limit(opts[:limit] || 50)
        self
      end
    end
  end
end
