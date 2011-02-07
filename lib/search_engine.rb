class SearchEngine
  # Return default kind of search engine to use.
  def self.default_kind
    return :acts_as_solr
  end

  # Kind of search engine to use?
  cattr_accessor :_kind

  # Return kind of search engine to use, e.g. :acts_as_solr.
  def self.kind
    return(self._kind.presence || self.default_kind)
  end

  # Activate the specified kind of search engine.
  def self.activate!(kind)
    self._kind = kind.to_sym
  end

  # Add searching to the specified class.
  #
  # Example:
  #   class MyModel < ActiveRecord::Base
  #     SearchEngine.add_searching_to(self)
  #   end
  def self.add_searching_to(model)
    search_engine_for(model).add_searching_to(model)
  end

  # Return class to use as driver for the model.
  def self.search_engine_for(model)
    return "SearchEngine::#{self.kind.to_s.classify}::#{model.name}".constantize
  end

  # Return class to use as search engine.
  def self.search_engine_class
    return "SearchEngine::#{self.kind.to_s.classify}".constantize
  end

  # Does the current search engine provide a score?
  def self.score?
    return self.search_engine_class.score?
  end
end
