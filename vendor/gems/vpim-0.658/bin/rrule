#!/usr/bin/env ruby

$-w = true
$:.unshift File.dirname($0) + "/../lib"

require 'vpim/rrule'
require 'getoptlong'
require 'parsedate'

HELP =<<EOF
Usage: #{$0} [options] rrule

Options
  -h,--help      Print this helpful message.
  -t,--start     Start time for recurrence rule, defaults to current time.

Examples:

FREQ=DAILY;COUNT=10
FREQ=DAILY;UNTIL=19971224T000000Z
FREQ=DAILY;INTERVAL=2
FREQ=DAILY;INTERVAL=10;COUNT=5

Demonstrate DST time change:

#{$0}  --start '2004-04-03 02:00' 'FREQ=daily;count=3'
#{$0}  --start '2004-10-30 02:00' 'FREQ=daily;count=3'

Note: In the US DST starts at 2AM, on the first Sunday of April, and reverts
at 2AM on the last Sunday of October.

EOF

dtstart = Time.new

opts = GetoptLong.new(
  [ "--help",    "-h",   GetoptLong::NO_ARGUMENT ],
  [ "--start",   "-t",   GetoptLong::REQUIRED_ARGUMENT]
)

opts.each do |opt, arg|
  case opt
    when "--help" then
      puts HELP
      exit 0

    when "--start" then
      date = ParseDate.parsedate(arg)
      date.pop
      date.pop
      dtstart = Time.local(*date)
  end
end

if ARGV.length < 1
  puts "no rrule specified, try -h!\n"
  exit 1
end

puts "Start: #{Vpim.encode_date_time(dtstart)}"

ARGV.each do |rule|
  rrule = Vpim::Rrule.new(dtstart, rule)

  puts "Rule: #{rule}"

  rrule.each_with_index do |t, count|
    puts format("count=%3d %s", count, t.to_s)
  end
end

