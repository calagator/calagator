# Exception raised if user requests parsing of a URL that requires
# authentication but none was provided.
class Calagator::Source::Parser
  class HttpAuthenticationRequiredError < RuntimeError
  end
end
