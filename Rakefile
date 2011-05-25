# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

require 'rake'
# require 'rake/testtask'
# require 'rdoc/task'

# require 'tasks/rails'

# Try to load `sunspot_rails` gem's tasks if available
begin
  require 'sunspot/rails/tasks' rescue nil
rescue LoadError => e
  # Ignore
end

Calagator::Application.load_tasks
