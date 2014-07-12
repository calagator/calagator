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
        def self.search(query, opts={})
          Event::Search::Sunspot.search(query, opts)
        end
      end
    else
      raise TypeError, "Unknown model class: #{model.name}"
    end
  end
end

