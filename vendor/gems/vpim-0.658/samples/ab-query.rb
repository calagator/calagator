#!/usr/bin/env ruby

$-w = true
$:.unshift File.dirname($0) + '/../lib'

require 'osx-wrappers'

require 'getoptlong'
require 'vpim/vcard'
require 'osx-wrappers'

HELP =<<EOF
Usage: ab-query.rb [--me] [--all]

Queries the OS X Address Book for vCards.

 -h, --help print this helpful message
 -m, --me   list my vCard
 -a, --all  list all vCards
EOF

opts = GetoptLong.new(
  [ "--help",    "-h",              GetoptLong::NO_ARGUMENT ],
  [ "--me",      "-m",              GetoptLong::NO_ARGUMENT ],
  [ "--all",     "-a",              GetoptLong::NO_ARGUMENT ]
)

abook = nil

opts.each do |opt, arg|
  case opt
    when "--help" then
      puts HELP
      exit 0

    when "--all" then
      abook = OSX::ABAddressBook.sharedAddressBook unless abook

      abook.people.to_a.each {
        |person|

        puts person.vCard
      }

    when "--me" then
     abook = OSX::ABAddressBook.sharedAddressBook unless abook

     puts abook.me.vCard
  end
end


unless abook
  puts HELP
  exit 1
end

