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
  -n,--name      Print the vCard name.
  -d,--debug     Print debug information.

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
    card.each do |field|
      puts "..#{field.name.capitalize}=#{field.value.inspect}"

      if field.group
        puts " group=#{field.group}"
      end

      field.each_param do |param, values|
        puts " #{param}=[#{values.join(", ")}]"
      end
    end

    if opt_name
      begin
      puts "#name=#{card.name.formatted}"
      rescue
        puts "! failed to decode name!"
      end
    end


    if opt_debug
      card.groups.sort.each do |group|
        card.enum_by_group(group).each do |field|
          puts "#{group} -> #{field.inspect}"
        end
      end
    end

    puts ""
  end
end

