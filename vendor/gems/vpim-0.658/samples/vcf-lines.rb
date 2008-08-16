#!/usr/bin/env ruby

$-w = true
$:.unshift File.dirname($0) + '/../lib'

require 'pp'
require 'getoptlong'
require 'vpim/vcard'

HELP =<<EOF
Usage: #{$0} <vcard>...

Options
  -h,--help      Print this helpful message.

Examples:
EOF

opt_name  = nil
opt_debug = nil

opts = GetoptLong.new(
  [ "--help",    "-h",              GetoptLong::NO_ARGUMENT ],
  [ "--name",    "-n",              GetoptLong::NO_ARGUMENT ],
  [ "--debug",   "-d",              GetoptLong::NO_ARGUMENT ]
)

opts.each do |opt, arg|
  case opt
    when "--help" then
      puts HELP
      exit 0

    when "--name" then
      opt_name = true

    when "--debug" then
      opt_debug = true
  end
end

if ARGV.length < 1
  puts "no vcard files specified, try -h!"
  exit 1
end

ARGV.each do |file|

  cards = Vpim::Vcard.decode(open(file))

  cards.each do |card|
    card.lines.each_with_index do |line, i|
      print line.name
      if line.group.length > 0
        print " (", line.group, ")"
      end
      print ": ", line.value.inspect, "\n"
    end
  end
end

