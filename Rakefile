#!/usr/bin/env rake
# frozen_string_literal: true

require 'bundler/setup'

APP_RAKEFILE = File.expand_path('spec/test_app/Rakefile', __dir__)
load 'rails/tasks/engine.rake'

Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

task spec: 'app:db:test:prepare'
task default: :spec
