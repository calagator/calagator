kind = SECRETS.search_engine.try(:to_sym)

Event::SearchEngine.use(kind)
Venue::SearchEngine.use(kind)
