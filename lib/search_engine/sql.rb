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
          wifi = opts[:wifi]
          include_closed = opts[:include_closed] == true
          limit = opts[:limit] || 50

          scoped_venues = Venue.non_duplicates
          # Pick a subset of venues (we want in_business by default)
          unless include_closed
            scoped_venues = scoped_venues.in_business
          end

          scoped_venues = scoped_venues.with_public_wifi if wifi

          order = \
            case opts[:order].try(:to_sym)
            when nil, :name, :title
              'LOWER(venues.title) ASC'
            else
              raise ArgumentError, "Unknown order: #{order}"
            end

          keywords = query.split(" ")
          tag_conditions = Array.new(keywords.size, "LOWER(tags.name) = ?").join(" OR ")

          conditions = ["title LIKE ? OR description LIKE ? OR (#{tag_conditions})", *(["%#{query}%", "%#{query}%"] + keywords) ]
          return scoped_venues.joins("LEFT OUTER JOIN taggings on taggings.taggable_id = venues.id AND taggings.taggable_type = 'Venue'",
                                     'LEFT OUTER JOIN tags ON tags.id = taggings.tag_id').where(conditions).order(order).group(Venue.columns.map(&:name).map{|attribute| "venues.#{attribute}"}.join(', ')).limit(limit)
        end
      end
    end
  end
end
