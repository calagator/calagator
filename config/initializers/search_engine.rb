kind = SECRETS.search_engine.try(:to_sym)

Calagator::Event::SearchEngine.use(kind)
Venue::SearchEngine.use(kind)
