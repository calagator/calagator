#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'

Sinatra::Application.default_options.merge!(
  :run => false,
  :env => :production
)

load 'start.rb'

run Sinatra.application
