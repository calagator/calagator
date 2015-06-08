desc "Update counter caches"
task :update_counter_caches => :environment do
  # Update the Venue#events_count
  total = Calagator::Venue.count
  Calagator::Venue.all.each do |venue|
    cached = venue.events_count
    actual = venue.events.count
    if actual != cached
      puts "Updating Venue ##{venue.id} from #{cached} cached to #{actual} actual -- #{venue.title}"
      Calagator::Venue.connection.update("UPDATE venues SET events_count = #{actual} WHERE id = #{venue.id}")
    end
  end
end
