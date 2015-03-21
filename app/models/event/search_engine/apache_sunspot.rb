class Event < ActiveRecord::Base
  class SearchEngine
    class ApacheSunspot < Struct.new(:query, :opts)
      # Return an Array of non-duplicate Event instances matching the search +query+..
      #
      # Options:
      # * :order => How to order the entries? Defaults to :score. Permitted values:
      #   * :score => Sort with most relevant matches first
      #   * :date => Sort by date
      #   * :name => Sort by event title
      #   * :title => same as :name
      #   * :venue => Sort by venue title
      # * :limit => Maximum number of entries to return. Defaults to 50.
      # * :skip_old => Return old entries? Defaults to false.
      def self.search(*args)
        new(*args).all
      end

      def self.score?
        true
      end

      def self.configure
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
      end

      def self.configured?
        Event.respond_to?(:solr_search)
      end

      def all
        current_events + past_events
      end

      private

      def current_events
        search(true)
      end

      def past_events
        skip_old ? [] : search(false)
      end

      def search(current)
        Event.solr_search do
          keywords query
          order_by *order
          order_by :start_time, :desc
          with :duplicate, false
          data_accessor_for(Event).include = [:venue]

          method = current ? :greater_than_or_equal_to : :less_than
          with(:start_time).send(method, Date.yesterday.to_time)
        end.results.take(limit)
      end

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
    end
  end
end
