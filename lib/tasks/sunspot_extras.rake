namespace :sunspot do
  namespace :reindex do
    desc "Reindex Calagator models with Sunspot"
    task :calagator => :environment do
      Event.remove_all_from_index
      Rake.application.invoke_task('sunspot:solr:reindex[500,Event]')
    end
  end

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

    desc "Start Sunspot's Solr if not already running"
    task :condstart do
      if running?
        puts "* Solr already running"
      else
        puts "* Starting Solr"
        Rake.application.invoke_task('sunspot:solr:start')
      end
    end

    desc "Restart Sunspot's Solr"
    task :restart do
      puts "* Restarting Solr"
      if running?
        Rake.application.invoke_task('sunspot:solr:stop')
      end
      Rake.application.invoke_task('sunspot:solr:start')
    end
  end
end
