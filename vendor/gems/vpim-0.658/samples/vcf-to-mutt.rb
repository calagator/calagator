#!/usr/bin/env ruby
#
# For a query command, mutt expects output of the form:
#
# informational line
# <email>TAB<name>[TAB<other info>]
# ...
#
# For an alias command, mutt expects output of the form:
# alias NICKNAME EMAIL
#
# NICKNAME shouldn't have spaces, and EMAIL can be either "user@example.com",
# "<user@example.com>", or "User <user@example.com>".

$-w = true
$:.unshift File.dirname($0) + '/../lib'


require 'getoptlong'
require 'vpim/vcard'

HELP =<<EOF
Usage: vcf-to-mutt.rb [--aliases] [query]

Queries a vCard file and prints the results in Mutt's query result format, or
as a Mutt alias file. No query matches all vCards.
  
The query is matched against all fields, so you can use 'climbers' to match all
vCards that has that string in the Notes field if you want to email all the
rock climbers you know. Or you can query all vCards with addresses in a
particular city, you get the idea.

Options
  -h,--help      Print this helpful message.
  -a,--aliases   Output an alias file, otherwise output a query response.

Examples:

Put in your muttrc file (either ~/.muttrc or ~/.mutt/muttrc) a line such as:

set query_command = "vcf-to-mutt.rb '%s' < ~/mycards.vcf"

Bugs:

 The aliases output file bases the alias name on the nickname, or the full
name, but either way, they aren't guaranteed to be unique if you have more than
email address in a vCard, or more than one vCard for the same nickname or full
name.
EOF

opt_query = ''
opt_aliases = false

opts = GetoptLong.new(
  [ "--help",    "-h",              GetoptLong::NO_ARGUMENT ],
  [ "--aliases", "-a",              GetoptLong::NO_ARGUMENT ]
)

opts.each do |opt, arg|
  case opt
    when "--help" then
      puts HELP
      exit 0

    when "--aliases" then
      opt_aliases = true
  end
end

opt_query = ARGV.first

module Mutt
  def Mutt.vcard_query(cards, query)
    query = query.downcase if query
    cards.find_all do |card|
      card.detect do |f|
        !query || f.value.downcase.include?(query)
      end
    end
  end

  def Mutt.query_print(cards, caption)
    puts caption

    cards.each do
      |vcard|
      # find the email addresses
      vcard.enum_by_name("email").each do |f|
        nn = vcard.nickname
        nn = nn ? "\t#{nn}" : ""
        puts "#{f.value}\t#{vcard['fn']}#{nn}"
      end
    end
  end

  def Mutt.alias_print(cards)
    cards.each do
      |vcard|
      # find the email addresses
      vcard.enum_by_name("email").each do |f|
        em = f.value
        fn = vcard['fn']
        nn = vcard.nickname || fn.gsub(/\s+/,'')
        puts "alias #{nn} #{fn} <#{em}>"
      end
    end
  end

end

cards = Vpim::Vcard.decode($stdin)

matches = Mutt::vcard_query(cards, opt_query)

if opt_aliases
  Mutt::alias_print(matches)
else
  qstr = opt_query == '' ? '<all records>' : opt_query;
  Mutt::query_print(matches, "Query #{qstr} against #{cards.size} vCards:")
end

