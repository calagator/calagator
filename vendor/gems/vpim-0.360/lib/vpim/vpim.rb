=begin
  Copyright (C) 2006 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

require 'vpim/version'

#:main:README
#:title:vpim - a library to manipulate vCards and iCalendars
module Vpim
  # Exception used to indicate that data being decoded is invalid, the message
  # should describe what is invalid.
  class InvalidEncodingError < StandardError; end

  # Exception used to indicate that data being decoded is unsupported, the message
  # should describe what is unsupported.
  #
  # If its unsupported, its likely because I didn't anticipate it being useful
  # to support this, and it likely it could be supported on request.
  class UnsupportedError < StandardError; end
  
  # Exception used to indicate that encoding failed, probably because the
  # object would not result in validly encoded data. The message should
  # describe what is unsupported.
  class Unencodeable < StandardError; end
end

module Vpim::Methods #:nodoc:
  module_function

  # Case-insensitive comparison of +str0+ to +str1+, returns true or false.
  # Either argument can be nil, where nil compares not equal to anything other
  # than nil.
  #
  # This is available both as a module function:
  #   Vpim::Methods.casecmp?("yes", "YES")
  # and an instance method:
  #   include Vpim::Methods
  #   casecmp?("yes", "YES")
  #
  # Will work with ruby1.6 and ruby 1.8.
  #
  # TODO - could make this be more efficient, but I'm supporting 1.6, not
  # optimizing for it.
  def casecmp?(str0, str1)
    if str0 == nil
      if str1 == nil
        return true
      else
        return false
      end
    end

    begin
      str0.casecmp(str1) == 0
    rescue NoMethodError
      str0.downcase == str1.downcase
    end
  end

end

