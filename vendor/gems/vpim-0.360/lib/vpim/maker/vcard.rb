=begin
  Copyright (C) 2006 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

require 'vpim/vcard'

module Vpim
  module Maker #:nodoc:backwards compat
    Vcard = Vpim::Vcard::Maker #:nodoc:backwards compat
  end
end

