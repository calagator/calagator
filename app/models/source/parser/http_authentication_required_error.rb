# Exception raised if user requests parsing of a URL that requires
# authentication but none was provided.
class Source::Parser
  class HttpAuthenticationRequiredError < Exception
  end
end
