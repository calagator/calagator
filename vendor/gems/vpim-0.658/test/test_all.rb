#!/usr/bin/env ruby

require 'pp'

$-w = true

$:.unshift File.dirname(__FILE__) + "/../lib"


pp [__LINE__, $:, $"]

require 'test/unit'

Dir[File.dirname(__FILE__) + "/test_*.rb"].each do |test|
  require test unless test =~ /test_all/
end

