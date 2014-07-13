require 'search_engine/base'

class SearchEngine::Sql < SearchEngine::Base
  score false

  def self.add_searching_to(model)
    case model.new
    when Venue
      model.class_eval do
      # Return an Array of non-duplicate Venue instances matching the search +query+..
        #
        # Options:
        # * :order => How to order the entries? Defaults to :name. Permitted values:
        #   * :name => Sort by event title
        #   * :title => same as :name
        # * :limit => Maximum number of entries to return. Defaults to +solr_search_matches+.
        # * :wifi => Require wifi
        # * :include_closed => Include closed venues? Defaults to false.
        def self.search(query, opts={})
          Venue::SearchEngine::Sql.search(query, opts)
        end
      end
    end
  end
end
