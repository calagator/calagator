#!/usr/bin/env rake
if !File.exist?("spec/dummy")
  raise "Missing dummy app in spec/dummy! Run bin/calagator new spec/dummy to generate one."
end

require 'bundler/setup'

APP_RAKEFILE = File.expand_path("../spec/dummy/Rakefile", __FILE__)
load 'rails/tasks/engine.rake'

Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

task :default => :spec
