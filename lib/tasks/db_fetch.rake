namespace :db do
  desc "Download a copy of the remote production database and replace the loca development database"
  task :fetch do
    require 'lib/database_yml_reader'
    d = DatabaseYmlReader.read

    puts "Backing up..."
    cp d.database, d.database + ".bak"

    puts "Downloading..."
    new = d.database + ".new"
    open(new, "w+") do |writer|
      require 'open-uri'
      open("http://calagator.org/export.sqlite3") do |reader|
        writer.write(reader.read)
      end
    end

    puts "Swapping..."
    mv new, d.database

    puts "Done"
  end
end
