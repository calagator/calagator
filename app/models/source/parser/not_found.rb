class Source::Parser
  # == Source::Parser::NotFound
  #
  # Exception thrown to indicate that the source isn't found and no other parsers should be tried.
  #
  # This exception should only be thrown by the canonical handler that can definitively tell if the source doesn't exist. For example, the Source::Parser::Facebook parser can throw this exception when given a http://facebook.com/ URLs because it can be sure whether these exist.
  class NotFound < StandardError
  end
end
