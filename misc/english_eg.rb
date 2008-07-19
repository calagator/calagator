#!/usr/bin/env ruby

require 'rubygems'

# On-line algorithms
require 'english/levenshtein'

# Off-line algorithms
require 'english/double_metaphone' # Handles spaces but returns either 4 or 8 character index
require 'english/metaphone' # Head comparable reductions of arbitrary length, could be translated to fixed numeric
require 'english/soundex' # Primitive and no spaces, but produces nearly numeric comparable output

#IK# names = %w(koshevoy kashivoiov kashmiri kasimov kasami)
names = [
  "Cube Space",
  "CubeSpace",
  "Cubespace",
  "CubSpacer",
  "FreeGeek",
]

timer = Time.now
count = 0

names.each_with_index do |source, source_index|
  names[source_index+1..names.size].each do |target|
    printf "* %s vs. %s\n", source, target
    printf "- soundex:     %s vs. %s\n", English::Soundex::soundex(source), English::Soundex::soundex(target) # E.g., C121
    printf "- metaphone:   %s vs. %s\n", English::Metaphone::metaphone(source), English::Metaphone::metaphone(target) # E.g., KBSPS
    printf "- double:      %s vs. %s\n", English::DoubleMetaphone[source].inspect, English::DoubleMetaphone[target].inspect # E.g., [KPSP,nil]
    printf "- levenshtein: %s\n", English::Levenshtein::distance(source, target) # E.g., 6
    count += 1
  end
end

timer_delta = Time.now-timer
printf "Total: %d operations in %f seconds, or %f o/s\n", count, timer_delta, count/timer_delta
# 10 ops, 1533 o/s on Core Duo 2 at 2GHz -- 4200 without Levenshtein

timer = Time.now
count = 5000
count.times do |i|
  English::Levenshtein::distance("koshevoy", "kashivoiov")
end
timer_delta = Time.now-timer
printf "Levenshtein: %d operations in %f seconds, or %f o/s\n", count, timer_delta, count/timer_delta
# 5000 ops, 1830 o/s on Core Duo 2 at 2GHz

__END__

def fact(n)
  if n == 0
    1
  else
    n * fact(n-1)
  end
end

# netc 4 == 10
def netc(n)
  if n == 0
    1
  else
    n + fact(n-1)
  end
end

?a == 97
'a'[0] == 97
97.chr == 'a'
'foo'.unpack('C*') == [102, 111, 111]
[102, 111, 111].pack('C*') == 'foo'

'kpss'.unpack('C*').map{|t| sprintf("%03d", t)}.join

def codes(value)
  cooked = value.gsub(/\W/, '')
  results = {}
  results[:soundex] = English::Soundex::soundex(cooked) # C121
  results[:metaphone] = English::Metaphone::metaphone(cooked) # E.g., KBSPS
  results[:double] = English::DoubleMetaphone[cooked].join
  return results
end

irb(main):097:0> codes 'kybespaze'
=> {:double=>"KPSP", :metaphone=>"KBSPS", :soundex=>"K121"}
irb(main):098:0> codes 'cubespace'
=> {:double=>"KPSP", :metaphone=>"KBSPS", :soundex=>"C121"}

def metaphone_for(value)
  cooked = value.gsub(/\W/, '')
  return English::Metaphone::metaphone(cooked) # E.g., KBSPS
end

# Long prefixes kill soundex and double-metaphone
irb(main):066:0> codes 'portland ruby brigade monthly meeting'
=> {:double=>"PRTL", :metaphone=>"PRTLNTRBBRKTMN0LMTNK", :soundex=>"P634"}
irb(main):067:0> codes 'portland ruby brigade code sprint'
=> {:double=>"PRTL", :metaphone=>"PRTLNTRBBRKTKTSPRNT", :soundex=>"P634"}

def str2num(value)
  return value.unpack('C*').map{|t| sprintf("%03d", t)}.join.to_i
end

differences at:      @                                                 @
str2num "PRTLNTRBBRKTMN0LMTNK" == 80082084076078084082066066082075084077078048076077084078075
str2num "PRTLNTRBBRKTKTSPRNT"  == 80082084076078084082066066082075084075084083080082078084

def dist(a, b)
  return 
end

dist 80082084076078084082066066082075084077078048076077084078075, 80082084076078084082066066082075084075084083080082078084


