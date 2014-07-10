class Event < ActiveRecord::Base
  class Search
    Sql = Struct.new(:query, :opts) do
      # Return an Array of non-duplicate Event instances matching the search +query+..
      #
      # Options:
      # * :order => How to order the entries? Defaults to :date. Permitted values:
      #   * :date => Sort by date
      #   * :name => Sort by event title
      #   * :title => same as :name
      #   * :venue => Sort by venue title
      # * :limit => Maximum number of entries to return. Defaults to +solr_search_matches+.
      # * :skip_old => Return old entries? Defaults to false.
      def self.search(*args)
        new(*args).search
      end

      def search
        limit order skip_old keywords scope
      end

      private
      
      def keywords scope
        query_conditions = query.split.inject(scope) do |query_conditions, keyword|
          like = "%#{keyword.downcase}%"
          query_conditions
            .where(['LOWER(events.title) LIKE ?', like])
            .where(['LOWER(events.description) LIKE ?', like])
            .where(['LOWER(events.url) LIKE ?', like])
            .where(['LOWER(tags.name) = ?', keyword])
        end
        scope.where(query_conditions.where_values.join(' OR '))
      end

      def skip_old scope
        if opts[:skip_old] == true
          scope.where("events.start_time >= ?", Date.yesterday.to_time)
        else
          scope
        end
      end

      def order scope
        order = case opts[:order].try(:to_sym)
        when :name, :title
          'LOWER(events.title) ASC'
        when :location, :venue
          'LOWER(venues.title) ASC'
        else
          'events.start_time DESC'
        end
        scope.order(order)
      end

      def limit scope
        limit = opts.fetch(:limit, 50)
        scope.limit(limit)
      end

      def scope
        column_names = Event.column_names.map { |name| "events.#{name}"}
        column_names << "venues.id"
        Event.scoped
          .group(column_names)
          .joins("LEFT OUTER JOIN taggings on taggings.taggable_id = events.id AND taggings.taggable_type = 'Event'")
          .joins("LEFT OUTER JOIN tags ON tags.id = taggings.tag_id")
          .includes(:venue)
      end
    end
  end
end

