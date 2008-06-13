namespace :solr do

  require "lib/solr_marshal"
  
  desc "Rebuild solr indexes"
  task :rebuild_index => :environment do
    Event.rebuild_solr_index
    Venue.rebuild_solr_index
  end
  
  desc "Dump solr data to FILE"
  task :dump => :environment do
    filename = SolrMarshal.dump(ENV["FILE"])
    puts "* Dumped Solr data to #{filename}"
  end

  desc "Restore solr data from FILE"
  task :restore => :environment do
    filename = ENV["FILE"] or raise ArgumentError, "Must specify a FILE argument, e.g. 'rake FILE=myindex.solr solr:restore'"
    SolrMarshal.restore(filename)
    puts "* Restored solr data from #{filename}"
  end

end
