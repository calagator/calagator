namespace :sunspot do
  desc "Optimize index and compress it to a smaller size"
  task :optimize => :environment do
    Sunspot.optimize
    Sunspot.commit
  end

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
