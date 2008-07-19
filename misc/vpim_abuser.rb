=begin
= Demonstration of how VPIM leaks memory

First download a very large feed to your local file system:
  wget http://www.google.com/calendar/ical/oregonstartups%40gmail.com/public/basic.ics -O oregonstartups.ics 

Next run this script:
  ./script/runner misc/vpim_leak.rb

The output is the RSS (resident size) and VSZ (virtual size) of the process. If it grows, there's a leak.
=end

def abuse
  SourceParser::Ical.to_abstract_events(:content => File.read('oregonstartups.ics'))
end

def measure
  system "ps -p #{$$} -o rss,vsz"
end

measure
5.times do
  abuse
  measure
end
