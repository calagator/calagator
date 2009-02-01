#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'

views_path = File.join(File.dirname(__FILE__), "views")
set :views, views_path
set :run, false
set :environment, :production

load 'start.rb'

run Sinatra::Application
