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
      port = Sunspot::Rails.configuration.port

      next puts "Solr already running" if WaitForSolr.running_on?(port)

      puts "Starting Solr ..."
      Rake.application.invoke_task('sunspot:solr:start:original')

      print "Waiting for Solr "
      WaitForSolr.on(port) { print "." }

      puts " done"
    end
  end
end
