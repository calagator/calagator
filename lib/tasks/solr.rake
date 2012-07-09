namespace :solr do

  desc "Rebuild solr indexes"
  task :rebuild_index => [:environment, :prepare] do
    Event.rebuild_solr_index
    Venue.rebuild_solr_index
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
