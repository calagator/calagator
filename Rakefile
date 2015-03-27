#!/usr/bin/env rake
if !File.exist?("spec/dummy")
  puts "Missing dummy app in spec/dummy! Run `bundle exec bin/calagator new spec/dummy --dummy` to generate one."
  exit 1
end

require 'bundler/setup'

APP_RAKEFILE = File.expand_path("../spec/dummy/Rakefile", __FILE__)
load 'rails/tasks/engine.rake'

Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

task :spec => 'app:db:test:prepare'
task :default => :spec
