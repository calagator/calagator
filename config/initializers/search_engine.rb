kind = SECRETS.search_engine.try(:to_sym)

Calagator::Event::SearchEngine.use(kind)
Calagator::Venue::SearchEngine.use(kind)
