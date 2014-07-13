# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

require 'rake'
# require 'rake/testtask'
# require 'rdoc/task'

# require 'tasks/rails'

Calagator::Application.load_tasks

task "sunspot:solr:start" do
  def solr_responding(port)
    system %(curl -o /dev/null "http://localhost:#{port}/solr" > /dev/null 2>&1)
  end

  print "Waiting for Solr."
  while !solr_responding(8981) do
    print "."
    sleep 1
  end
  puts "done."
end
