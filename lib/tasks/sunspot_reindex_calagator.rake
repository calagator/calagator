desc "Reindex Calagator models with Sunspot"
task "sunspot:reindex:calagator" => :environment do
  Rake.application.invoke_task('sunspot:solr:reindex[500,Event]')
  Rake.application.invoke_task('sunspot:solr:reindex[500,Venue]')
end

