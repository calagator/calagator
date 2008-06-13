namespace :data do
  task :prepare do
    require 'lib/data_marshal'
  end

  desc "Dumps state to FILE, defaults to DBNAME.TIMESTAMP.data"
  task :dump => :prepare do
    filename = DataMarshal.dump(ENV["FILE"])
    puts "* Dumped data to #{filename}"
  end

  desc "Restores state from FILE"
  task :restore => :prepare do
    filename = ENV["FILE"] or raise ArgumentError, "The data:restore task requires a FILE argument to define which file to restore from, e.g. 'rake FILE=current.data data:restore'"
    DataMarshal.restore(filename)
    puts "* Restored state from #{filename}"

    # TODO automate
    puts "!!! You must restart Solr to use this new data"
  end

  desc "Fetch state from production server and install it locally"
  task :fetch => :prepare do
    source = "http://#{PRODUCTION_HOSTNAME}/export.data"
    #IK# source = "http://localhost:3000/export.data" # Only for testing
    target = "export.data"

    puts "* Downloading #{source}..."
    open(target, "w+"){|writer| writer.write(open(source).read)}

    puts "* Replacing data..."
    DataMarshal.restore(target)

    # TODO automate
    puts "!!! You must restart Solr to use this new data"

    puts "* Done"
  end
end
