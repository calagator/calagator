# Database dump and export tasks, specific to SQLite

namespace :db do
  require 'lib/db_marshal'

  desc "Dump database to FILE, defaults to DBNAME.TIMESTAMP.sql"
  task :dump => :environment do
    filename = DbMarshal.dump(ENV["FILE"])
    puts "* Dumped database to #{filename}"
  end

  desc "Restores database from FILE"
  task :restore => :environment do
    filename = ENV["FILE"] or raise ArgumentError, "The db:restore task requires a FILE argument to define which file to restore from, e.g. 'rake FILE=mydb.sql db:restore'"
    DbMarshal.restore(filename)
    puts "* Restored database from #{filename}"
  end
end
