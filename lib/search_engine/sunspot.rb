require 'lib/search_engine/base'

class SearchEngine::Sunspot < SearchEngine::Base
  score true

  def self.add_searching_to(model)
    case model.new
    when Venue, Source
      # Do nothing
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

          # Sunspot 1.2.1 seems to ignore pagination, e.g.:
          ### paginate(:page => 1, :per_page => 100)
          Sunspot.config.pagination.default_per_page = 100

          searcher = Sunspot.search(self) do
            keywords(query)

            order_by(:start_time, :desc)

            with(:duplicate_for_solr, false)

            if skip_old
              with(:start_time).greater_than(Date.yesterday.to_time)
            end
          end

          # Sort using Ruby to provide more meaningful results, by fetching the
          # most recent events that match and then sorting them. In contrast,
          # if Solr were to sort the results, it would do so globally and there
          # are many cases where no current events would be shown.
          hits = searcher.hits
          event_ids = hits.map(&:primary_key)
          events = Event.all(:conditions => ['events.id in (?)', event_ids], :include => [:venue])
          return \
            case opts[:order].try(:to_sym)
            when :date
              events.sort_by(&:start_time)
            when :venue, :location
              events.sort_by(&:location)
            when :name, :title
              events.sort_by(&:title)
            else # :score, nil, ''
              ids_to_hits = {}
              for hit in hits
                ids_to_hits[hit.primary_key.to_i] = hit
              end

              for event in events
                event.class_eval { attr_accessor :score }
                event.score = ids_to_hits[event.id].score
              end

              events.sort_by(&:score).reverse
            end
        end

        def venue_title_for_solr
          return self.venue.try(:title)
        end

        # Do this last to prevent Sunspot from taking over our ::search method.
        unless RAILS_ENV == 'test'
          # Why aren't these loaded by default!?
          include Sunspot::Rails::Searchable unless defined?(self.solr_search)
          Sunspot::Adapters::InstanceAdapter.register(Sunspot::Rails::Adapters::ActiveRecordInstanceAdapter, self)
          Sunspot::Adapters::DataAccessor.register(Sunspot::Rails::Adapters::ActiveRecordDataAccessor, self)

          searchable do
            text :title, :default_boost => 10
            string :title

            text :description

            text :tag_list, :default_boost => 10


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
