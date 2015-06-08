desc "Reindex Calagator models with Sunspot"
task "sunspot:reindex:calagator" do
  # Silence warnings about already-initialized constants caused by
  # sunspot-rails' aggressive eager loading of all engine files.
  original_verbosity = $VERBOSE
  $VERBOSE = nil

  puts "Reindexing Venues…"
  Rake.application['sunspot:solr:reindex'].invoke(500, "Calagator::Venue")

  Rake.application['sunspot:solr:reindex'].reenable
  Rake.application['sunspot:reindex'].reenable

  puts "Reindexing Events…"
  Rake.application['sunspot:solr:reindex'].invoke(500, "Calagator::Event")

  $VERBOSE = original_verbosity
end

