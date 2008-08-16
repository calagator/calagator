#!/usr/bin/env ruby

require 'vpim/vcard'
require 'vpim/icalendar'

$in  = ARGV.first ? File.open(ARGV.shift) : $stdin
$out = ARGV.first ? File.open(ARGV.shift, 'w') : $stdout

cal = Vpim::Icalendar.create

Vpim::Vcard.decode($in).each do |card|
  if card.birthday
    cal.push Vpim::Icalendar::Vevent.create_yearly(
      card.birthday,
      "Birthday for #{card['fn'].strip}"
      )
    $stderr.puts "#{card['fn']} -> bday #{cal.events.last.dtstart}"
  end
end

puts cal.encode

