namespace :solr do

  task :prepare do
    require "lib/solr_marshal"
  end

  desc "Rebuild solr indexes"
  task :rebuild_index => [:environment, :prepare] do
    Event.rebuild_solr_index
    Venue.rebuild_solr_index
  end

  desc "Dump solr data to FILE"
  task :dump => [:environment, :prepare] do
    filename = SolrMarshal.dump(ENV["FILE"])
    puts "* Dumped Solr data to #{filename}"
  end

  desc "Restore solr data from FILE"
  task :restore => [:environment, :prepare] do
    filename = ENV["FILE"] or raise ArgumentError, "Must specify a FILE argument, e.g. 'rake FILE=myindex.solr solr:restore'"
    SolrMarshal.restore(filename)
    puts "* Restored solr data from #{filename}"

    Rake::Task['solr:restart'].invoke
  end

  task :restart => :environment do
    if RUBY_PLATFORM.match(/mswin/)
      puts <<-HERE
========================================================================
WARNING: Windows can't automatically restart Solr, you must do so
manually by killing it through the Task Manager and then run: rake
  rake solr:start
========================================================================
      HERE
    else
      puts "* Restarting Solr..."
      Rake::Task['solr:stop'].invoke
      Rake::Task['solr:start'].invoke
    end
  end

end
