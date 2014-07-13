class Venue < ActiveRecord::Base
  class SearchEngine
    Sunspot = Struct.new(:query, :opts) do
      # Return an Array of non-duplicate Venue instances matching the search +query+..
      #
      # Options:
      # * :order => How to order the entries? Defaults to :score. Permitted values:
      #   * :score => Sort with most relevant matches first
      #   * :name => Sort by event title
      #   * :title => same as :name
      # * :limit => Maximum number of entries to return. Defaults to +solr_search_matches+.
      # * :wifi => Require wifi
      # * :include_closed => Include closed venues? Defaults to false.
      def self.search(query, opts={})
        wifi = opts[:wifi]
        include_closed = opts[:include_closed] == true
        limit = opts[:limit] || 50

        # Sunspot 1.2.1 seems to ignore pagination, e.g.:
        ### paginate(:page => 1, :per_page => 100)
        ::Sunspot.config.pagination.default_per_page = 100

        ordering = \
          case opts[:order].try(:to_sym)
          when :name, :title
            [:title, :asc]
          when :score
            [:score, :desc]
          else
            nil
          end

        searcher = Venue.solr_search do
          keywords(query)
          ordering ?
            order_by(*ordering) :
            order_by(:score, :desc)
          with(:duplicate_for_solr, false)
          with(:wifi, true) if wifi
          with(:closed, false) unless include_closed
        end

        searcher.results.take(limit)
      end

      Venue.searchable do
        text :title, :default_boost => 3
        string :title
        text :description
        text :address
        text :street_address
        text :postal_code
        text :locality
        text :region
        text :tag_list, :default_boost => 3
        text :url
        boolean :closed
        boolean :wifi
        boolean :duplicate_for_solr do |record|
          record.duplicate_of_id.present?
        end
      end
    end
  end
end
