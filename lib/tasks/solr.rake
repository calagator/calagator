namespace :solr do

  def running?
    pidfile = "#{Rails.root}/tmp/pids/sunspot-solr-#{Rails.env}.pid"

    begin
      pid = File.read(pidfile).to_i
    rescue Errno::ENOENT
      return false
    end

    begin
      Process.kill(0, pid)
      return pid
    rescue Errno::ESRCH
      File.delete(pidfile) # Remove stale pidfile
      return false
    end
  end

  desc "Rebuild solr indexes"
  task :rebuild_index => [:environment, :prepare] do
    Event.rebuild_solr_index
    Venue.rebuild_solr_index
  end

  desc "Restart solr"
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

  desc "Start solr if it's not already running"
  task :condstart => :environment do
    if running?
      puts "* Solr already running"
    else
      puts "* Starting Solr"
      Rake::Task['solr:start'].invoke
    end
  end

end
