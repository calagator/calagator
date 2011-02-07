namespace :sunspot do
  namespace :reindex do
    desc "Reindex Calagator's models with Sunspot"
    task :calagator => :environment do
      Event.remove_all_from_index
      Sunspot.optimize
      Sunspot.commit
      Event.find_in_batches(:batch_size => 100, :include => [:venue, :tags]) do |events|
        events.each(&:index)
      end
      Sunspot.optimize
      Sunspot.commit
    end
  end
end
