require 'active_record'

namespace :test do
  task :migrate do
    ActiveRecord::Migrator.migrate("test/db/migrate/", ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
  end
end
