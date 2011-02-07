class SearchEngine::ActsAsSolr::Source
  def self.add_searching_to(model)
    model.class_eval do
      # Names of columns and methods to create Solr indexes for
      def self.solr_indexable_fields
        return %w[
          title
        ].map(&:to_sym)
      end
    end
  end
end
