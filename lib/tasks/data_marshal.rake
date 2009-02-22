namespace :data do
  task :prepare do
    require 'lib/data_marshal'
    require 'open-uri'
  end

  desc "Dumps state to FILE, defaults to DBNAME.TIMESTAMP.data"
  task :dump => :prepare do
    filename = DataMarshal.dump(ENV["FILE"])
    puts "* Dumped data to #{filename}"
  end

  desc "Restores state from FILE"
  task :restore => [:prepare, "tmp:cache:clear"] do
    filename = ENV["FILE"] or raise ArgumentError, "The data:restore task requires a FILE argument to define which file to restore from, e.g. 'rake FILE=current.data data:restore'"
    DataMarshal.restore(filename)
    puts "* Restored state from #{filename}"

    Rake::Task['solr:restart'].invoke
    
    puts "* Done"
  end

  desc "Fetch state from production server and install it locally"
  task :fetch => :prepare do
    source = SETTINGS.url + "export.data"
    #IK# source = "http://localhost:3000/export.data" # Only for testing
    target = "export.data"

    puts "* Downloading #{source}..."
    File.open(target, "wb+") do |writer| 
      # NOTE Do not use File.open, open-uri doesn't intercept URL calls to that
      open(source, "rb") do |reader|
        writer.write(reader.read)
      end
    end

    puts "* Replacing data..."
    DataMarshal.restore(target)

    Rake::Task['solr:restart'].invoke

    Rake::Task['db:migrate'].invoke

    puts "* Done"
  end
end
