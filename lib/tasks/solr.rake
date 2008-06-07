namespace :solr do
  
  desc 'Rebuild solr indexes'
  task :rebuild_index => :environment do
    Event.rebuild_solr_index
    Venue.rebuild_solr_index
  end
  
end