class SearchEngine::ActsAsSolr::Venue
  def self.add_searching_to(model)
    model.class_eval do
      # Names of columns and methods to create Solr indexes for
      def self.solr_indexable_fields
        return %w[
          title
          description
          address
          url
          street_address
          locality
          region
          postal_code
          country
          latitude
          longitude
          email
          telephone
          tag_list
        ].map(&:to_sym)
      end

      unless RAILS_ENV == 'test'
        acts_as_solr :fields => solr_indexable_fields
      end
    end
  end
end
