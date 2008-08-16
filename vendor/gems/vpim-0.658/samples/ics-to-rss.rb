#!/usr/bin/env ruby
#
# Call with --print to print RSS to stdout, otherwise it runs as a WEBrick
# servelet on port 8080.
#
# This comes from an idea of Dave Thomas' that he described here:
#
#   http://pragprog.com/pragdave/Tech/Blog/ToDos.rdoc
#
# He generously sent me his code, and I reimplemented it with vPim and rss/maker.
#
# RSS Content-Types:
#
#   RSS 1.0 -> application/rdf+xml
#   RSS 2.0 -> text/xml
#   RSS 0.9 -> text/xml
#   ATOM    -> application/xml

require 'rss/maker'
require 'vpim/icalendar'

class IcalToRss
  def initialize(calendars, title, link, language = 'en-us')
    @rss = RSS::Maker.make("0.9") do |maker|
      maker.channel.title = title
      maker.channel.link = link
      maker.channel.description = title
      maker.channel.language = language

      # These are required, or RSS::Maker silently returns nil!
      maker.image.url = "maker.image.url"
      maker.image.title = "maker.image.title"

      calendars.each do |file|
        Vpim::Icalendar.decode(File.open(file)).each do |cal|
          cal.todos.each do |todo|
            if !todo.status || todo.status.upcase != "COMPLETED"
              item = maker.items.new_item
              item.title = todo.summary
              item.link =  todo.properties['url'] || link
              item.description = todo.description || todo.summary
            end
          end
        end
      end
    end
  end

  def to_rss
    @rss.to_s
  end
end

TITLE = "Sam's ToDo List"
LINK  = "http://ensemble.local/~sam"

if ARGV[0] == "--print"

  puts IcalToRss.new( Dir[ "/Users/sam/Library/Calendars/*.ics" ], TITLE, LINK ).to_rss

else

  require 'webrick'

  class IcalRssTodoServlet < WEBrick::HTTPServlet::AbstractServlet
    def do_GET(req, resp)   
      resp.body = IcalToRss.new( Dir[ "/Users/sam/Library/Calendars/*.ics" ], TITLE, LINK ).to_rss
      resp['content-type'] = 'text/xml'
      raise WEBrick::HTTPStatus::OK
    end
  end

  server = WEBrick::HTTPServer.new( :Port => 8080 )

  server.mount( '/', IcalRssTodoServlet )

  ['INT', 'TERM'].each { |signal| 
    trap(signal) { server.shutdown }
  }

  server.start

end

