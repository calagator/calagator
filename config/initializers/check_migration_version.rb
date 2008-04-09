# Lifted from Advanced Rails Recipes #38: Fail Early --
# Check to make sure we've got the right database version;
# skip when run from tasks like rake db:migrate, or from Capistrano rules
# that need to run before the migration rule
current_version = ActiveRecord::Migrator.current_version rescue 0
highest_version = Dir.glob("#{RAILS_ROOT}/db/migrate/*.rb" ).map { |f|
  f.match(/(\d+)_.*\.rb$/) ? $1.to_i : 0
}.max

abort "Database isn't the current migration version: " \
      "expected #{highest_version}, got #{current_version}" \
  unless current_version == highest_version or \
  defined?(Rake) or ENV['NO_MIGRATION_CHECK'] 

