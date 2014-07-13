class Venue < ActiveRecord::Base
  class SearchEngine
    Sql = Struct.new(:query, :opts) do
      def self.search(*args)
        new(*args).search
      end

      def search
        base.keywords.non_duplicates.with_wifi.in_business.order.limit.scope
      end

      protected

      attr_accessor :scope

      def base
        column_names = Venue.column_names.map { |name| "venues.#{name}" }
        @scope = Venue.scoped
          .group(column_names)
          .joins("LEFT OUTER JOIN taggings on taggings.taggable_id = venues.id AND taggings.taggable_type = 'Venue'")
          .joins("LEFT OUTER JOIN tags ON tags.id = taggings.tag_id")
        self
      end

      def keywords
        query_conditions = query.split.inject(@scope) do |query_conditions, keyword|
          like = "%#{keyword.downcase}%"
          query_conditions
            .where(['LOWER(title) LIKE ?', like])
            .where(['LOWER(description) LIKE ?', like])
            .where(['LOWER(tags.name) = ?', keyword])
        end
        @scope = @scope.where(query_conditions.where_values.join(' OR '))
        self
      end

      def non_duplicates
        @scope = @scope.non_duplicates
        self
      end

      def order
        @scope = @scope.order('LOWER(venues.title) ASC')
        self
      end

      def limit
        @scope = @scope.limit(opts[:limit] || 50)
        self
      end

      def with_wifi
        @scope = @scope.with_public_wifi if opts[:wifi]
        self
      end

      def in_business
        @scope = @scope.in_business unless opts[:include_closed]
        self
      end
    end
  end
end

