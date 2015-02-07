require "wait_for_solr"

task "sunspot:solr:start_with_waiting" => :environment do
  port = Sunspot::Rails.configuration.port

  next puts "Solr already running" if WaitForSolr.running_on?(port)

  puts "Starting Solr ..."

  # is namespaced within app when invoked from the engine repo
  task = Rake::Task.task_defined?("app:sunspot:solr:start") ? "app:sunspot:solr:start" : "sunspot:solr:start"
  Rake.application.invoke_task(task)

  print "Waiting for Solr "
  WaitForSolr.on(port, 30) { print "." }

  puts " done"
end

