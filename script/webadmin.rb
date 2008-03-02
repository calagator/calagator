#!/usr/bin/env ruby

# This is a simple, stand-alone web application that provides a way to start, stop, restart, status check, and deploy the application. Execute this program with a "-h" flag for usage instructions.

require 'rubygems'
require 'ramaze'
require 'optparse'

# {{{
PROG = File.basename(__FILE__)
OWN_FILE = File.expand_path(__FILE__)
PID_FILE = OWN_FILE+".pid"
SOCK_FILE = OWN_FILE+".sock"
RAILS_ENV = ENV['CALAGATOR_DEVELOPMENT'] ? "development" : "production"
RAILS_ROOT = File.expand_path(File.dirname(File.dirname(__FILE__)))

# Are we running in production mode?
def production?; RAILS_ENV == "production"; end

# Is process running? Returns PID if true, false otherwise.
def running?
  if File.exist?(PID_FILE)
    pid = File.read(PID_FILE).to_i
    begin
      # Running
      Process.kill(0, pid)
      return pid
    rescue Errno::ESRCH
      # Removed stale PID file
      File.unlink(PID_FILE)
      return false
    end
  else
    # Not running
    return false
  end
end

options = {}
opts = OptionParser.new do |opts|
  opts.banner = <<-HERE
Usage: #{PROG} [options]

Examples:
  #{PROG} attach  # Attaches to daemon
  #{PROG} start   # Starts daemon
  #{PROG} stop    # Stops daemon
  #{PROG} restart # Restarts daemon

Options, meant for internal use:
  HERE
  opts.on("-d", "--daemonize", "Daemonize script") do |v|
    options[:daemonize] = v
  end
  opts.on("-a", "--attach", "Attach to script") do |v|
    options[:attach] = v
  end
  opts.on("-h", "--help", "Show this help")
  args = opts.parse!(ARGV)

  if args.include? "start"
    puts "Starting"
    exec "dtach -n #{SOCK_FILE} #{OWN_FILE} --daemonize"
  elsif args.include? "restart"
    puts "Restarting"
    system "#{__FILE__} stop; sleep 3; #{__FILE__} start"
    exit 0
  elsif args.include? "stop"
    if pid = running?
      Process.kill("TERM", pid)
      puts "Stopped PID #{pid}"
      exit 0
    else
      puts "Not running"
      exit 1
    end
  elsif args.include? "status"
    if pid = running?
      puts "Running at PID #{pid}"
      exit 0
    else
      puts "Not running"
      exit 7
    end
  elsif args.include? "attach" || options[:attach]
    exec "dtach -a #{SOCK_FILE}"
  end
  if !options[:daemonize]
    puts opts.help
    puts "ERROR: Unknown arguments #{args.size > 0 ? (' -- '+args.inspect) : ''}"
    exit 1
  end
end
# }}}

class MainController < Ramaze::Controller
  engine :Haml

# {{{
  if production?
    def error() 'An error occurred. Contact one of the developers.' end
  end
# }}}

  def index
    case request["action"]
    when "deploy"
      @message = `(cd #{RAILS_ROOT} && svn cleanup && svn update -r #{request["revision"].match(/(\w+)/)[1]} && rake db:migrate restart) 2>&1`
    when "restart", "start", "stop", "status"
      @message = `(cd #{RAILS_ROOT} && rake #{request["action"]}) 2>&1`
    end

    %(
!!!
%html
  %head
    %title calagator admin console
  %body
    %h1 calagator admin console
    %p 
      %form{:method=>"post"}
        %label
          %input{:type=>"radio", :name=>"action", :value=>"status", :checked=>"checked"}
          status
        %br
        %label
          %input{:type=>"radio", :name=>"action", :value=>"deploy"}
          deploy and migrate revision
          %input{:type=>"text", :name=>"revision", :value=>"HEAD"}
        %br
        %label
          %input{:type=>"radio", :name=>"action", :value=>"restart"}
          restart
        %br
        %label
          %input{:type=>"radio", :name=>"action", :value=>"start"}
          start
        %br
        %label
          %input{:type=>"radio", :name=>"action", :value=>"stop"}
          stop
        %br
        %p
          %input{:type=>"submit", :value=>"submit"}
        %pre
    - if @message
      %pre
        ~ @message
    )
  end
end

puts "Starting#{production? ? " production" : ""} server at PID: #{Process.pid}"
File.open(PID_FILE, "w+"){|h| h.write(Process.pid)}

Ramaze.start({ 
  :adapter => :mongrel, 
  :host => production? ? 'localhost' : '*', 
  :port => 20019,
  :sourcereload => production? ? false : true,
})
