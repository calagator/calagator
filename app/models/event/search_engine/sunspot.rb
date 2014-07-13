class Event < ActiveRecord::Base
  class SearchEngine
    Sunspot = Struct.new(:query, :opts) do
      # Return an Array of non-duplicate Event instances matching the search +query+..
      #
      # Options:
      # * :order => How to order the entries? Defaults to :score. Permitted values:
      #   * :score => Sort with most relevant matches first
      #   * :date => Sort by date
      #   * :name => Sort by event title
      #   * :title => same as :name
      #   * :venue => Sort by venue title
      # * :limit => Maximum number of entries to return. Defaults to +solr_search_matches+.
      # * :skip_old => Return old entries? Defaults to false.
      def self.search(*args)
        new(*args).search
      end

      def initialize(*args)
        super
        configure unless configured?
      end

      def search
        Event.solr_search do
          keywords query, minimum_match: 1
          order_by *order
          order_by :start_time, :desc
          with :duplicate, false
          with(:start_time).greater_than(Date.yesterday.to_time) if skip_old
          data_accessor_for(Event).include = [:venue]
        end.results.take(limit)
      end

      private

      def order
        case opts[:order].try(:to_sym)
        when :date
          [:start_time, :desc]
        when :venue, :location
          [:venue_title, :asc]
        when :name, :title
          [:title, :asc]
        else
          [:score, :desc]
        end
      end

      def skip_old
        opts[:skip_old] == true
      end

      def limit
        opts[:limit] || 50
      end

      def configure
        Event.searchable do
          text :title, :default_boost => 3
          string :title

          text :description

          text :tag_list, :default_boost => 3

          text :url

          time :start_time
          time :end_time

          text :venue_title
          string :venue_title

          boolean(:duplicate) { |event| event.duplicate? }
        end
        Event.reindex
        ::Sunspot.commit
      end

      def configured?
        Event.respond_to?(:solr_search)
      end
    end
  end
end

