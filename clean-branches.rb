#!/usr/bin/env ruby

$stdin.each_line do |branch| 
  /remotes\/([^\/]*)\/([^\/]*)/.match(branch)
  puts `git push #{$1} :#{$2}`
end
