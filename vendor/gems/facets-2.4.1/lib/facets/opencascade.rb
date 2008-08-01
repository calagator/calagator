# = OpenCascade
#
# OpenCascade is a subclass of OpenObject. It differs in a few
# significant ways, in particular entries cascade to new entries.
#
# The main reason this class is labeled "cascade", every internal
# Hash is trandformed into an OpenCascade dynamically upon access.
# This makes it easy to create "cascading" references.
#
#   h = { :x => { :y => { :z => 1 } } }
#   c = OpenCascade[h]
#   c.x.y.z  #=> 1
#
# == Authors
#
# * Thomas Sawyer
#
# == Todo
#
# * Think about this more!
# * What about parent when descending downward?
#   Should parent even be part of OpenObject?
#   Maybe that should be in a differnt class?
# * Should cascading work via hash on the fly like this?
#   Or perhaps converted all at once?
# * Returning nil doesn't work if assigning!
#
# == Copying
#
# Copyright (c) 2006 Thomas Sawyer
#
# Ruby License
#
# This module is free software. You may use, modify, and/or redistribute this
# software under the same terms as Ruby.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.

require 'facets/boolean' # bool
require 'facets/openobject'
#require 'facets/nullclass'

# = OpenCascade
#
# OpenCascade is subclass of OpenObject. It differs in a few
# significant ways.
#
# The main reason this class is labeled "cascade", every internal
# Hash is trandformed into an OpenCascade dynamically upon access.
# This makes it easy to create "cascading" references.
#
#   h = { :x => { :y => { :z => 1 } } }
#   c = OpenCascade[h]
#   c.x.y.z  #=> 1
#
#--
# Last, when an entry is not found, 'null' is returned rather then 'nil'.
# This allows for run-on entries withuot error. Eg.
#
#   o = OpenCascade.new
#   o.a.b.c  #=> null
#
# Unfortuately this requires an explict test for of nil? in 'if' conditions,
#
#   if o.a.b.c.null?  # True if null
#   if o.a.b.c.nil?   # True if nil or null
#   if o.a.b.c.not?   # True if nil or null or false
#
# So be sure to take that into account.
#++

class OpenCascade < OpenObject

  def method_missing( sym, arg=nil )
    type = sym.to_s[-1,1]
    name = sym.to_s.gsub(/[=!?]$/, '').to_sym
    if type == '='
      self[name] = arg
    elsif type == '!'
      self[name] = arg
      self
    else
      val = self[name]
      val = object_class[val] if Hash === val
      val
    end
  end

end

