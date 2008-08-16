#!/usr/bin/env ruby

$-w = true
$:.unshift File.dirname($0) + '/../lib'

require 'getoptlong'

require 'vpim/icalendar'
require 'vpim/duration'

include Vpim

# TODO - $0 is the full path, fix it.
HELP =<<EOF
Usage: #{$0} <invitation.ics>

Options
  -h,--help         Print this helpful message.
  -d,--debug        Print debug information.

  -m,--my-addrs     My email addresses, a REGEX.
Examples:
EOF

opt_debug = nil
opt_print = true

# Ways to get this:
#  Use a --mutt option, and steal it from muttrc,
#  from $USER, $LOGNAME,, from /etc/passwd...
opt_myaddrs = nil

opts = GetoptLong.new(
  [ "--help",    "-h",   GetoptLong::NO_ARGUMENT ],

  [ "--myaddrs", "-m",   GetoptLong::REQUIRED_ARGUMENT ],

  [ "--accept",  "-a",   GetoptLong::REQUIRED_ARGUMENT ],
  [ "--reject",  "-r",   GetoptLong::REQUIRED_ARGUMENT ],
  [ "--debug",   "-d",   GetoptLong::NO_ARGUMENT ]
)

opts.each do |opt, arg|
  case opt
    when "--help" then
      puts HELP
      exit 0

    when "--debug" then
      require 'pp'
      opt_debug = true

    when "--myaddrs" then
      opt_myaddrs = Regexp.new(arg, 'i')
  end
end

if ARGV.length < 1
  puts "no input files specified, try -h!\n"
  exit 1
end

ARGV.each do |file|
  cals = Vpim::Icalendar.decode(File.open(file))

  cals.each do |cal|
    if opt_debug
      puts "vCalendar: version=#{cal.version/10.0} producer='#{cal.producer}'"
      if cal.protocol; puts "  protocol-method=#{cal.protocol}"; end
    end

    events = cal.events

    if events.size != 1
      raise "!! #{events.size} calendar events is more than 1!"
    end

    events.each do |e|
      summary = e.summary || e.comment || ''

      case cal.protocol.upcase
        when 'PUBLISH'
          puts "Notification of:  #{summary}"

        when 'REQUEST'
          puts "Request for:  #{summary}"

        when 'REPLY'

        else
          raise "!! unhandled protocol type #{cal.protocol}!"
      end

      puts "Organized by: #{e.organizer.to_s}"

      # TODO - spec as hours/mins/secs
      e.occurrences.each_with_index do |t, i|
        if(i < 1)
          puts "At time: #{t}" +( e.duration ? " for #{Duration.secs(e.duration).to_s}" : '' )
        else
          puts "... and others"
          break
        end
      end

      if e.location;     puts "Located at: #{e.location}"; end

      if e.description
        puts finish="-- Description --"
        puts e.description
      end

      if e.comments
        puts finish="-- Comment --"
        puts "   comment=#{e.comments}"
      end

      if e.attendees.first

        puts finish="-- Attendees --"

        e.attendees.each_with_index do |a,i|
          puts "#{i} #{a.to_s}"
          if !opt_myaddrs || a.uri =~ opt_myaddrs
            puts "  participation-status: #{a.partstat ? a.partstat.downcase : 'unknown'}"
            puts "  response-requested? #{a.rsvp ? 'yes' : 'no'}"
          end
        end
      end

      if finish
        puts '-' * finish.length
      end

      if opt_debug
        if e.status;       puts "   status=#{e.status}"; end
                           puts "   uid=#{e.uid}"
                           puts "   dtstamp=#{e.dtstamp.to_s}"
                           puts "   dtstart=#{e.dtstart.to_s}"
        if e.dtend;        puts "     dtend=#{e.dtend.to_s}"; end
        if e.rrule;        puts "   rrule=#{e.rrule}"; end
      end
    end

    todos = cal.todos
    todos.each do |e|
      s = e.status ? " (#{e.status})" : ''
      puts "Todo#{s}: #{e.summary}"
    end

    if opt_debug
      pp cals
    end
  end
end

