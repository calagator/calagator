namespace :sunspot do
  namespace :reindex do
    desc "Reindex Calagator models with Sunspot"
    task :calagator => :environment do
      Rake.application.invoke_task('sunspot:solr:reindex[500,Event]')
      Rake.application.invoke_task('sunspot:solr:reindex[500,Venue]')
    end
  end

  namespace :solr do
    task :start do
      def solr_responding(port)
        system %(curl -o /dev/null "http://localhost:#{port}/solr" > /dev/null 2>&1)
      end

      print "Waiting for Solr."
      while !solr_responding(Sunspot::Rails.configuration.port) do
        print "."
        sleep 1
      end
      puts "done."
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

    def running?
      pidfile = "#{Rails.root}/tmp/pids/sunspot-solr-#{Rails.env}.pid"
      pid = File.read(pidfile).to_i
      Process.kill(0, pid)
      pid
    rescue Errno::ENOENT
      false
    rescue Errno::ESRCH
      File.delete(pidfile) # Remove stale pidfile
      false
    end
  end
end
