class Event < ActiveRecord::Base
  class SearchEngine
    cattr_accessor(:kind) { :sql }

    def self.search(*args)
      search_engine.search(*args)
    end

    def self.score?
      search_engine.score?
    end

    private_class_method

    def self.search_engine
      if kind == :sunspot
        Event::SearchEngine::Sunspot
      else
        Event::SearchEngine::Sql
      end
    end
  end
end
