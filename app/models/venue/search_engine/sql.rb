class Venue < ActiveRecord::Base
  class SearchEngine
    Sql = Struct.new(:query, :opts) do
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

        keywords = query.split
        like = "%#{query.downcase}%"
        tag_conditions = Array.new(keywords.size, "LOWER(tags.name) = ?").join(" OR ")
        conditions = ["LOWER(title) LIKE ? OR LOWER(description) LIKE ? OR (#{tag_conditions})", *([like, like] + keywords) ]
        scoped_venues = scoped_venues.where(conditions) if keywords.any?

        scoped_venues = scoped_venues.joins("LEFT OUTER JOIN taggings on taggings.taggable_id = venues.id AND taggings.taggable_type = 'Venue'",
                                   'LEFT OUTER JOIN tags ON tags.id = taggings.tag_id').order(order).group(Venue.columns.map(&:name).map{|attribute| "venues.#{attribute}"}.join(', ')).limit(limit)
      end
    end
  end
end
