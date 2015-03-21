require "wait_for_solr"
require "rake_override_task"

override_task "sunspot:solr:start" do
  port = Sunspot::Rails.configuration.port

  next puts "Solr already running" if WaitForSolr.running_on?(port)

  puts "Starting Solr ..."
  Rake.application.invoke_task('sunspot:solr:start:original')

  print "Waiting for Solr "
  WaitForSolr.on(port, 30) { print "." }

  puts " done"
end

