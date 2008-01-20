#!/usr/bin/env ruby

require 'rubygems'
require 'ramaze'

class MainController < Ramaze::Controller
  engine :Haml

  RAILS_ROOT = File.expand_path(File.dirname(File.dirname(__FILE__)))

  def index
    case request["action"]
    when "deploy"
      @message = `(cd #{RAILS_ROOT} && svn cleanup && svn update -r #{request["revision"].match(/(\w+)/)[1]} && rake restart) 2>&1`
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
          deploy revision
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

# TODO accept all ips?
Ramaze.start :adapter => :mongrel, :host => "*", :port => 7000
