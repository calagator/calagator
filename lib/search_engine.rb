# = SearchEngine
#
# The SearchEngine class and associated logic provide a pluggable search engine
# for Calagator.
#
# If you're administering a Calagator instance and are looking for instructions
# on configuring search, see the `INSTALL.md` file's "Search engine" section.
#
# == Things related to searching
#
# === Secrets
#
# Administrators of a Calagator instance can specify which search engine to use
# by setting the `search_engine` field in the `config/secets.yml` to the name
# of the search engine to use, e.g. `sunspot`. If one isn't set, a sensible
# default search engine is used.
#
# === SearchEngine
#
# This module activates a search engine implementation, queries its
# capabilities, and adds searching to models, e.g.:
#
#   class MyModel < ActiveRecord::Base
#     include SearchEngine
#   end
#
# ===  SearchEngine::Base
#
# Base class for search engine implementations.
#
# === SearchEngine implementations, e.g. SearchEngine::Sunspot
#
# These classes describe the behavior of a particular search engine. These
# inject code into models that `include SearchEngine`.
#
# == Environment
#
# The `config/environment.rb` activates a search engine implementation, and
# specifies, loads and configures any libraries it requires.
module SearchEngine
  # Add searching to the ActiveRecord +model+ class, e.g. Event.
  def self.included(model)
    if ActiveRecord::Base.connection.tables.include?(model.table_name)
      return implementation.add_searching_to(model)
    end
  end

  # Set kind of search engine to use, e.g. :sunspot.
  def self.kind=(value)
    case value
    when nil, ''
      @@kind = :sql
    else
      @@kind = value.to_s.underscore.to_sym
    end

    return @@kind
  end

  # Return kind of search engine to use, e.g. :sunspot.
  def self.kind
    return @@kind
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
