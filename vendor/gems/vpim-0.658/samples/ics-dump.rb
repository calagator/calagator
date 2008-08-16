#!/usr/bin/env ruby
#
# Calendars are in ~/Library/Calendars/

$-w = true
$:.unshift File.dirname($0) + '/../lib'

require 'getoptlong'
require 'pp'
require 'open-uri'

require 'vpim/icalendar'
require 'vpim/duration'

include Vpim

HELP =<<EOF
Usage: #{$0} <vcard>...

Options
  -h,--help         Print this helpful message.
  -n,--node         Dump as nodes.
  -d,--debug        Print debug information.
  -m,--metro        Convert metro.

Examples:
EOF

opt_debug = nil
opt_node  = false

opts = GetoptLong.new(
  [ "--help",    "-h",   GetoptLong::NO_ARGUMENT ],
  [ "--node",    "-n",   GetoptLong::NO_ARGUMENT ],
  [ "--debug",   "-d",   GetoptLong::NO_ARGUMENT ]
)

opts.each do |opt, arg|
  case opt
    when "--help" then
      puts HELP
      exit 0

    when "--node" then
      opt_node = true

    when "--debug" then
      opt_debug = true
  end
end

if ARGV.length < 1
  puts "no input files specified, try -h!\n"
  exit 1
end

if opt_node

  ARGV.each do |file|
    tree = Vpim.expand(Vpim.decode(File.open(file).read(nil)))
    pp tree
  end

  exit 0
end

def v2s(v)
  case v
  when Vpim::Icalendar::Attachment
    if v.binary
      "#{v.format.inspect} binary #{v.binary.inspect}"
    else
      s = "#{v.format.inspect} uri #{v.uri.inspect}"
      begin
        s << " #{v.value.gets.inspect}..."
      rescue
        s << " (#{$!.class})"
      end
    end
  else
    v #.inspect
  end
end


def puts_properties(c)
  [
    :access_class,
    :attachments,
    :categories,
    :comments,
    :completed,
    :contacts,
    :created,
    :description,
    :dtend,
    :dtstamp,
    :dtstart,
    :due,
    :geo,
    :location,
    :organizer,
    :percent_complete,
    :priority,
    :sequence,
    :status,
    :summary,
    :transparency,
    :uid,
    :url,
  ].each do |m|
    if c.respond_to? m
      v = c.send(m)
      case v
      when Array
        v.each_with_index do |v,i|
          puts "  #{m}[#{i}]=<#{v2s v}>"
        end
      else
        if v
          puts "  #{m}=<#{v2s v}>"
        end
      end
    end
  end

  begin
    if c.duration;     puts "   duration=#{Duration.secs(c.duration).to_s}"; end
  rescue NoMethodError
  end

  c.attendees.each_with_index do |a,i|
    puts "  attendee[#{i}]=#{a.to_s}"
    puts "   role=#{a.role.upcase} participation-status=#{a.partstat.upcase} rsvp?=#{a.rsvp ? 'yes' : 'no'}"
  end

  [
    'RRULE',
    'RDATE',
    'EXRULE',
    'EXDATE',
  ].each do |m|
    c.propvaluearray(m).each_with_index do |v,i|
      puts "  #{m}[#{i}]=<#{v.to_s}>"

      case
      when i == 1 && m != 'RRULE'
        # Anything that isn't an RRULE isn't supported at all.
        puts "  ==> #{m} is unsupported!"
      when i == 2 && m == 'RRULE'
        # If there was more than 1 RRULE, its not supported.
        puts "  ==> More than one RRULE is unsupported!"
      end
    end
  end

  begin
    c.occurrences.each_with_index do |t, i|
      if(i < 10)
        puts "   #{i+1} -> #{t}"
      else
        puts "   ..."
        break;
      end
    end
  rescue ArgumentError
    # No occurrences.
  end

end

ARGV.each do |file|
  puts "===> ", file
  cals = Vpim::Icalendar.decode(
    (file == "-") ? $stdin : open(file)
    )

  cals.each_with_index do |cal, i|
    if i > 0
      puts
    end

    puts "Icalendar[#{i}]:"
    puts " version=#{cal.version/10.0}"
    puts " producer=#{cal.producer}"

    if cal.protocol; puts " protocol=#{cal.protocol}"; end

    events = cal.events

    cal.components.each_with_index do |c, i|
        puts " #{c.class.to_s.sub(/.*::/,'')}[#{i}]:"

        begin
          puts_properties(c)
        rescue => e
          cb = e.backtrace
          pp e
          print cb.shift, ":", e.message, " (", e.class, ")\n"
          cb.each{|c| print "\tfrom ", c, "\n"}
          exit 1
        end
    end

    if opt_debug
      pp cals
    end
  end
end

