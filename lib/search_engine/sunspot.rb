require 'search_engine/base'

class SearchEngine::Sunspot < SearchEngine::Base
  score true

  def self.add_searching_to(model)
    case model.new
    when Source
      # Do nothing
    when Venue
      # Add search to venues
      model.class_eval do
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
          Sunspot.config.pagination.default_per_page = 100

          ordering = \
            case opts[:order].try(:to_sym)
            when :name, :title
              [:title, :asc]
            when :score
              [:score, :desc]
            else
              nil
            end

          searcher = self.solr_search do
            keywords(query)
            ordering ?
              order_by(*ordering) :
              order_by(:score, :desc)
            with(:duplicate_for_solr, false)
            with(:wifi, true) if wifi
            with(:closed, false) unless include_closed
          end

          return searcher.results.uniq
        end
          # return venues

        # Do this last to prevent Sunspot from taking over our ::search method.
        unless Rails.env == 'test'
          # Why aren't these loaded by default!?
          include Sunspot::Rails::Searchable unless defined?(self.solr_search)
          Sunspot::Adapters::InstanceAdapter.register(Sunspot::Rails::Adapters::ActiveRecordInstanceAdapter, self)
          Sunspot::Adapters::DataAccessor.register(Sunspot::Rails::Adapters::ActiveRecordDataAccessor, self)

          searchable do
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
    when Event
      model.class_eval do
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
          skip_old = opts[:skip_old] == true
          limit = opts[:limit] || 50

          # This method fetches events using two separate searches. Current
          # events are fetched and sorted by default using relevance scores, so
          # that the most meaningful events are at the top. Past events are
          # fetched and sorted by default using date, so that the most recent
          # events involving the search term are at the top.

          # Sunspot 1.2.1 seems to ignore pagination, e.g.:
          ### paginate(:page => 1, :per_page => 100)
          Sunspot.config.pagination.default_per_page = 100

          ordering = \
            case opts[:order].try(:to_sym)
            when :date
              [:start_time, :desc]
            when :venue, :location
              [:venue_title_for_solr, :asc]
            when :name, :title
              [:title, :asc]
            when :score
              [:score, :desc]
            else
              nil
            end

          events = []

          searcher = self.solr_search do
            keywords(query)
            ordering ?
              order_by(*ordering) :
              order_by(:score, :desc)
            with(:duplicate_for_solr, false)
            with(:start_time).greater_than(Date.yesterday.to_time)
            data_accessor_for(self).include = [:venue]
          end
          events += searcher.results

          unless skip_old
            searcher = self.solr_search do
              keywords(query)
              ordering ?
                order_by(*ordering) :
                order_by(:start_time, :desc)
              with(:duplicate_for_solr, false)
              with(:start_time).less_than(Date.yesterday.to_time + 1.second)
              data_accessor_for(self).include = [:venue]
            end
            events += searcher.results
          end

          return events.uniq
        end
          # return events

        def venue_title_for_solr
          return self.venue.try(:title)
        end

        # Do this last to prevent Sunspot from taking over our ::search method.
        unless Rails.env == 'test'
          # Why aren't these loaded by default!?
          include Sunspot::Rails::Searchable unless defined?(self.solr_search)
          Sunspot::Adapters::InstanceAdapter.register(Sunspot::Rails::Adapters::ActiveRecordInstanceAdapter, self)
          Sunspot::Adapters::DataAccessor.register(Sunspot::Rails::Adapters::ActiveRecordDataAccessor, self)

          searchable do
            text :title, :default_boost => 3
            string :title

            text :description

            text :tag_list, :default_boost => 3

            text :url

            time :start_time
            time :end_time

            text :venue_title_for_solr
            string :venue_title_for_solr

            boolean :duplicate_for_solr do |record|
              record.duplicate_of_id.present?
            end
          end
        end
      end
    else
      raise TypeError, "Unknown model class: #{model.name}"
    end
  end
end

if defined?(Sunspot)
  # Monkeypatch Sunspot to connect to Solr server. Sigh. For details, see:
  # http://groups.google.com/group/ruby-sunspot/browse_thread/thread/34772773b4b5682d
  module Sunspot::Rails
    def slave_config(sunspot_rails_configuration)
      config = Sunspot::Configuration.build
      config.solr.url = URI::HTTP.build(
          :host => sunspot_rails_configuration.hostname,
          :port => sunspot_rails_configuration.port,
          :path => sunspot_rails_configuration.path
        ).to_s
      config
    end
  end
  Sunspot.session = Sunspot::Rails.build_session
end
