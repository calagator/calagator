# = SearchEngine
#
# The SearchEngine class and associated logic provide a pluggable search engine
# for Calagator.
#
# Parts:
# * SearchEngine: This class is used to activate search engines, query their
#   capabilities and add searching to models.
# * SearchEngine implementation: E.g. SearchEngine::Sunspot describes the
#   behavior of the `sunspot` search engine.
# * Secrets: The `search_engine` setting in the `config/secets.yml` specifies the
#   particular search engine to use, such as `sunspot`.
# * Environment: The `config/environment.rb` loads the specified search
# 	engine's plugins and libraries, and configures them.
class SearchEngine
  # Set kind of search engine to use, e.g. :acts_as_solr.
  def self.kind=(value)
    case value
    when nil, ''
      @@kind = :sql
    else
      @@kind = value.to_s.underscore.to_sym
    end

    return @@kind
  end

  # Return kind of search engine to use, e.g. :acts_as_solr.
  def self.kind
    return @@kind
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
    begin
      return "SearchEngine::#{self.kind.to_s.classify}".constantize
    rescue NameError
      raise ArgumentError, "Invalid search engine specified in 'config/secrets.yml': #{self.kind}"
    end
  end

  # Does the current search engine provide a score?
  def self.score?
    return self.implementation.score?
  end
end
