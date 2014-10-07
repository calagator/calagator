require "wait_for_solr"

Rake::TaskManager.class_eval do
  def alias_task name
    new_name = "#{name}:original"
    @tasks[new_name] = @tasks.delete(name)
  end
end

namespace :sunspot do
  namespace :reindex do
    desc "Reindex Calagator models with Sunspot"
    task :calagator => :environment do
      Rake.application.invoke_task('sunspot:solr:reindex[500,Event]')
      Rake.application.invoke_task('sunspot:solr:reindex[500,Venue]')
    end
  end

  namespace :solr do
    Rake.application.alias_task 'sunspot:solr:start'

    task :start do
      Rake.application.invoke_task('sunspot:solr:start:original')

      print "* Waiting for Solr"
      WaitForSolr.on Sunspot::Rails.configuration.port do
        print "."
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
