#!/usr/bin/env ruby

$-w = true
$:.unshift File.dirname($0) + '/../lib'

require 'vpim/vcard'

ARGV.each do |file|

  File.open(file).each do |line|

    if line =~ /\s*alias\s+(\w+)\s+(.*)/
      nick = $1
      rhs  = $2
      email = nil
      name = nil

      case rhs
        when /(.*)<(.*)>/
          email = $2
          name = $1
        else
          email = rhs
          name = nick
          nick = nil
      end

      card = Vpim::Vcard::Maker.make2 do |maker|
        # don't have the broken-down name, we'll have to leave it blank
        maker.name { |n| n.fullname = name }

        # Set preferred, its the only one...
        maker.add_email( email ) { |e| e.preferred = true }

        maker.nickname = nick if nick
       
        # mark as auto-generated, it makes it easier to see them
        maker.add_field( Vpim::DirectoryInfo::Field.create('note', "auto-generated-from-mutt-aliases") )
      end

      puts card.to_s
    end
  end
end

