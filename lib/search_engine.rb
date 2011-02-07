# = SearchEngine
#
# The SearchEngine class and associated logic provide a pluggable search engine
# for Calagator.
#
# Parts:
# * SearchEngine implementation: E.g. SearchEngine::Sunspot describes the
#   behavior of the `sunspot` search engine.
# * Secrets: The `search_engine` setting in the `config/secets.yml` specifies the
#   particular search engine to use, such as `sunspot`.
# * Environment: The `config/environment.rb` loads the specified search
# 	engine's plugins and libraries, and configures them.
class SearchEngine
  # Return default kind of search engine to use.
  def self.default_kind
    return :sql
  end

  # Return kind of search engine to use, e.g. :acts_as_solr.
  def self.kind
    return(@@_kind.presence || self.default_kind)
  end

  # Activate the specified kind of search engine.
  def self.activate!(kind)
    @@_kind = kind.try(:to_sym) || self.default_kind
  end

  # Add searching to the specified class.
  #
  # Example:
  #   class User < ActiveRecord::Base
  #     SearchEngine.add_searching_to(self)
  #   end
  def self.add_searching_to(model)
    return implementation.add_searching_to(model)
  end

  # Return class to use as search engine.
  def self.implementation
    return "SearchEngine::#{self.kind.to_s.classify}".constantize
  end

  # Does the current search engine provide a score?
  def self.score?
    return self.implementation.score?
  end
end
