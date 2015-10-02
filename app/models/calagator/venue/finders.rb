module Calagator
  class Venue < ActiveRecord::Base
    module Finders
      def masters
        non_duplicates.includes(:source, :events, :tags, :taggings)
      end

      def with_public_wifi
        where(wifi: true)
      end

      def in_business
        where(closed: false)
      end

      def out_of_business
        where(closed: true)
      end

      def search(query, opts={})
        SearchEngine.search(query, opts)
      end
    end
  end
end
