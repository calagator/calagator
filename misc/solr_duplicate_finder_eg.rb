# TODO rework text_for_solr to remove non-word characters
event = Event.find(:first)
query = SolrQuery.new{Fuzzy(event.text_for_solr)}.to_s.gsub(/[^\w\s]/, ' ')
rs = Event.find_by_solr(query, :scores => true, :order => "score asc")

