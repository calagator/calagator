# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

require 'tasks/rails'

# Try to load `sunspot_rails` gem's tasks if available
begin
  require 'sunspot/rails/tasks' rescue nil
rescue LoadError => e
  # Ignore
end
