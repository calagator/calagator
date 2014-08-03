class Venue < ActiveRecord::Base
  class SearchEngine
    class ApacheSunspot < Struct.new(:query, :opts)
      # Return an Array of non-duplicate Venue instances matching the search +query+..
      #
      # Options:
      # * :order => How to order the entries? Defaults to :score. Permitted values:
      #   * :score => Sort with most relevant matches first
      #   * :name => Sort by event title
      #   * :title => same as :name
      # * :limit => Maximum number of entries to return. Defaults to 50.
      # * :wifi => Require wifi
      # * :include_closed => Include closed venues? Defaults to false.
      def self.search(*args)
        new(*args).search
      end

      def initialize(*args)
        super
        configure unless configured?
      end

      def search
        Venue.solr_search do
          keywords query
          order_by *order
          with :duplicate_for_solr, false
          with :wifi, true if wifi
          with :closed, false unless include_closed
        end.results.take(limit)
      end

      private

      def order
        case opts[:order].try(:to_sym)
        when :name, :title
          [:title, :asc]
        else
          [:score, :desc]
        end
      end

      def wifi
        opts[:wifi]
      end

      def include_closed
        opts[:include_closed]
      end

      def limit
        opts[:limit] || 50
      end

      def configure
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
        Venue.reindex
        Sunspot.commit
      end

      def configured?
        Venue.respond_to?(:solr_search)
      end
    end
  end
end
