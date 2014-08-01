class Venue < ActiveRecord::Base
  class SearchEngine
    cattr_accessor(:kind) { :sql }

    def self.search(*args)
      search_engine.search(*args)
    end

    private_class_method

    def self.search_engine
      if kind == :sunspot
        Venue::SearchEngine::Sunspot
      else
        Venue::SearchEngine::Sql
      end
    end
  end
end
