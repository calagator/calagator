class SearchEngine::Base
  # TODO is the cattr_accessor properly inheritable on its own?
  # def self.inherited(subclass)
    # subclass.class_eval do
      cattr_accessor :_score
    # end
  # end

  # Does this search engine provide a score?
  def self.score?
    return self._score != false
  end

  # Set whether this search engine provides a score.
  def self.score(value)
    self._score = value
  end
end
