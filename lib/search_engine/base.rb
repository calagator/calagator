require 'search_engine'

# = SearchEngine::Base
#
# This class describes common behavior for search engine implementations, e.g.
# the Sunspot search engine implementation would subclass this.
#
# == Usage
#
# Create a subclass to describe your search engine, indicate whether the search
# engine provides a ::score to rank the relevance of matches, and
# ::add_searching_to method for adding this search engine's logic to the model.
#
#   class SearchEngine::Foo < SearchEngine::Base
#     score true
#
#     def self.add_searching_to(model)
#       ...
#     end
#   end
class SearchEngine::Base
  def self.inherited(subclass)
    subclass.class_eval do
      cattr_accessor :_score
    end
  end

  # Does this search engine provide a score?
  def self.score?
    return self._score != false
  end

  # Set whether this search engine provides a score.
  def self.score(value)
    self._score = value
  end
end
