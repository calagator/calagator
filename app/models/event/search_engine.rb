class Event < ActiveRecord::Base
  class SearchEngine
    cattr_accessor(:kind) { :sql }
  end
end
