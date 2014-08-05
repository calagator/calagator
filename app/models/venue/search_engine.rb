class Venue < ActiveRecord::Base
  class SearchEngine
    cattr_accessor(:kind) { :sql }

    def self.search(*args)
      search_engine.search(*args)
    end

    def self.use(kind)
      self.kind = kind
      search_engine.configure if search_engine.respond_to?(:configure)
    end

    private_class_method

    def self.search_engine
      kind == :sunspot ? ApacheSunspot : Sql
    end
  end
end
