require File.dirname(__FILE__) + '/../solr_fixtures'

namespace :db do
  namespace :fixtures do
    desc "Load fixtures into the current environment's database. Load specific fixtures using FIXTURES=x,y"
    task :load => :environment do
      begin
        ActsAsSolr::Post.execute(Solr::Request::Delete.new(:query => "*:*"))
        ActsAsSolr::Post.execute(Solr::Request::Commit.new)
        (ENV['FIXTURES'] ? ENV['FIXTURES'].split(/,/) : Dir.glob(File.join(RAILS_ROOT, 'test', 'fixtures', '*.{yml,csv}'))).each do |fixture_file|    
          ActsAsSolr::SolrFixtures.load(File.basename(fixture_file, '.*'))
        end 
        puts "The fixtures loaded have been added to Solr"       
      rescue
      end
    end
  end
end