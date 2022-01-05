# frozen_string_literal: true

class Calagator::Source::Parser
  # == Source::Parser::NotFound
  #
  # Exception thrown to indicate that the source isn't found and no other parsers should be tried.
  #
  # This exception should only be thrown by the canonical handler that can definitively tell if the source doesn't exist.
  class NotFound < StandardError
  end
end
