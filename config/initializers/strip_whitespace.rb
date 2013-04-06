require 'strip_whitespace'
class ActiveRecord::Base
  include StripWhitespace
end