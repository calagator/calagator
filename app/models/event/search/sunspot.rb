class Event < ActiveRecord::Base
  class Search
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
      def self.search(query, opts={})
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

        skip_old = opts[:skip_old] == true
        limit = opts[:limit] || 50

        # This method fetches events using two separate searches. Current
        # events are fetched and sorted by default using relevance scores, so
        # that the most meaningful events are at the top. Past events are
        # fetched and sorted by default using date, so that the most recent
        # events involving the search term are at the top.
        ordering = \
          case opts[:order].try(:to_sym)
          when :date
            [:start_time, :desc]
          when :venue, :location
            [:venue_title, :asc]
          when :name, :title
            [:title, :asc]
          when :score
            [:score, :desc]
          else
            nil
          end

        searcher = Event.solr_search do
          keywords query, minimum_match: 1
          # FIXME figure out how to implement selective substring matching
          # keywords "*#{query}*", minimum_match: 1, fields: :url
          ordering ?
            order_by(*ordering) :
            order_by(:score, :desc)
            order_by(:start_time, :desc)
          with(:duplicate, false)
          with(:start_time).greater_than(Date.yesterday.to_time) if opts[:skip_old]
          data_accessor_for(Event).include = [:venue]
        end
        searcher.results.take(limit)
      end
    end
  end
end

