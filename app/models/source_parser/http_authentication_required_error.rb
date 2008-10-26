# Exception raised if user requests parsing of a URL that requires
# authentication but none was provided.
class SourceParser
  class HttpAuthenticationRequiredError < Exception
  end
end
