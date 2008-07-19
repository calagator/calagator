module ActsAsSolr

  class SolrFixtures
    def self.load(table_names)
      [table_names].flatten.map { |n| n.to_s }.each do |table_name|
        klass = instance_eval(File.split(table_name.to_s).last.to_s.gsub('_',' ').split(" ").collect{|w| w.capitalize}.to_s.singularize)
        klass.rebuild_solr_index if klass.respond_to?(:rebuild_solr_index)
      end
      ActsAsSolr::Post.execute(Solr::Request::Commit.new)
    end
  end
  
end