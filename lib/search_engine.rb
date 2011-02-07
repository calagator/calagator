# = SearchEngine
#
# The SearchEngine class and associated logic provide a pluggable search engine
# for Calagator.
#
# Parts:
# * SearchEngine subclass: E.g. SearchEngine::Sunspot describes the behavior of
#   the `sunspot` search engine.
# * SearchEngine subclass models: E.g. SearchEngine::Sunspot::Event describes
#   the behavior of the `sunspot` search engine for the Event model.
# * Secrets: The `search_engine` setting in the `config/secets.yml` specifies the
#   particular search engine to use, such as `sunspot`.
# * Environment: The `config/environment.rb` loads the specified search
# 	engine's plugins and libraries, and configures them.
class SearchEngine
  # Return default kind of search engine to use.
  def self.default_kind
    return :sql
  end

  # Kind of search engine to use?
  cattr_accessor :_kind

  # Return kind of search engine to use, e.g. :acts_as_solr.
  def self.kind
    return(self._kind.presence || self.default_kind)
  end

  # Activate the specified kind of search engine.
  def self.activate!(kind)
    self._kind = kind.try(:to_sym) || self.default_kind
  end

  # Add searching to the specified class, by finding a class specific to the
  # search engine for this model and using it to alter the base model.
  #
  # Example of usage, where the base User model class would be updated using
  # the SearchEngine::Sunspot::User class specific to the search engine,
  # assuming you're using `sunspot` as your search engine:
  #   class User < ActiveRecord::Base
  #     SearchEngine.add_searching_to(self)
  #   end
  def self.add_searching_to(model)
    begin
      model_search_engine = search_engine_for(model)
    rescue ArgumentError => e
      # Ignore files that don't exist, assuming that they don't exist because no override is needed.
      return false
    end

    model_search_engine.add_searching_to(model)
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
