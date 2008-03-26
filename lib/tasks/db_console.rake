namespace :db do
  desc "Get a database console"
  task :console do
    require 'lib/database_yml_reader'
    d = DatabaseYmlReader.read

    exec "sqlite3 #{d.database}"
  end
end

