#!/usr/bin/env ruby

$-w = true

require 'ubygems' rescue "ignored"

require 'getoptlong'
require 'pp'
require 'plist'

require 'vpim/repo'

$stdout.sync = true
$stderr.sync = true

HELP =<<EOF
Usage: #{$0} [where]

Shows events and todos occuring soon.

By default, the Apple iCal v3 calendars are used, but if a location where
.ics files is specified, any calendars found there will be used.

Options
  -h,--help        Print this helpful message.
  -n,--days   N    How many of the next days are considered to be "soon", default
                     is seven.
  -v,--verbose     Print more information about upcoming events.
EOF

opt_debug = nil
opt_verbose = nil
opt_days  = 7

opts = GetoptLong.new(
  [ "--help",    "-h",   GetoptLong::NO_ARGUMENT ],
  [ "--days",    "-n",   GetoptLong::REQUIRED_ARGUMENT ],
  [ "--verbose", "-v",   GetoptLong::NO_ARGUMENT ],
  [ "--debug",   "-d",   GetoptLong::NO_ARGUMENT ]
)

opts.each do |opt, arg|
  case opt
    when "--help" then
      puts HELP
      exit 0

    when "--days" then
      opt_days = arg.to_i

    when "--verbose" then
      opt_verbose = true

    when "--debug" then
      opt_verbose = true
      opt_debug = true
  end
end

calendars = []

if ARGV.length > 0
  Vpim::Repo::Directory.each(ARGV.first) do |cal|
    calendars << cal
  end
else
  Vpim::Repo::Ical3.each() do |cal|
    calendars << cal
  end
end

if opt_debug
  pp ARGV
  pp calendars
end

SECSPERDAY = (24 * 60 * 60)

t0 = Time.new.to_a
t0[0] = t0[1] = t0[2] = 0 # sec,min,hour = 0
t0 = Time.local(*t0)
t1 = t0 + opt_days * SECSPERDAY

if opt_debug
  puts "to: #{t0}"
  puts "t1: #{t1}"
end

if opt_verbose
  puts "Events in the next #{opt_days} days:"
end

# Collect all events, then all todos.
all_events = []
all_todos  = []

calendars.each do |cal|
  if opt_debug; puts cal.name; end

  begin
    cal.events.each do |e|
      begin
        if opt_debug; pp e; end
        if e.occurs_in?(t0, t1)
          if e.summary
            all_events.push(e)
          end
        end
      rescue
        $stderr.puts "error in #{cal.name} (\"#{e.summary}\"): #{$!.to_s}"
      end
    end

    all_todos.concat(cal.todos)
  end
end

puts

def start_of_first_occurrence(t0, t1, e)
  e.occurrences(t1) do |t|
    # An event might start before t0, but end after it..., in which case
    # we are still interested.
    if (t + (e.duration || 0)) >= t0
      return t
    end
  end
  nil
end

all_events.sort! do |lhs, rhs|
  start_of_first_occurrence(t0, t1, lhs) <=> start_of_first_occurrence(t0, t1, rhs)
end

all_events.each do |e|
  puts "#{e.summary}:"

  if opt_verbose
    if e.description;   puts "  description=#{e.description}"; end
    if e.comments;      puts "  comment=#{e.comments.first}"; end
    if e.location;      puts "  location=#{e.location}"; end
    if e.status;        puts "  status=#{e.status}"; end
    if e.dtstart;       puts "  dtstart=#{e.dtstart}"; end
    if e.duration;      puts "  duration=#{Vpim::Duration.new(e.duration).to_s}"; end
  end

  i = 1
  e.occurrences.each_until(t1).each do |t|
    # An event might start before t0, but end after it..., in which case
    # we are still interested.
    dstr = ''
    if e.duration
      d = e.duration
      dstr = " for #{Vpim::Duration.new(e.duration).to_s}"
    end

    if (t + (e.duration || 0)) >= t0
      puts "  ##{i} on #{t}#{dstr}"
      i += 1
    end
  end
end

=begin
def fix_priority(vtodo)
  p = vtodo.priority
  if !p
    p = 10

end
=end

all_todos.sort! do |x,y|
  x = x.priority
  y = y.priority

  # 0 means no priority, put these last, not first
  x = 10 if x == 0
  y = 10 if y == 0

  x <=> y
end

priorities = [
  'no importance',
  'very important',
  'very important',
  'very important',
  'important',
  'important',
  'important',
  'not important',
  'not important',
  'not important'
]

all_todos.each do |e|
  status = e.status || 'Todo'
  if status != 'COMPLETED'
    puts "#{status.capitalize}: #{e.summary}" #  (#{priorities[e.priority]})"
  end
end

