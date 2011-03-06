namespace :data do
  def restart_search_service
    case SearchEngine.kind
    when :acts_as_solr
      puts "* Restarting acts_as_solr's solr..."
      Rake::Task['solr:restart'].invoke
    when :sunspot
      puts "* Restarting sunspot's solr..."
      begin
        Rake::Task['sunspot:solr:stop'].invoke
      rescue Sunspot::Server::NotRunningError:
        # Ignore
      end
      Rake::Task['sunspot:solr:start'].invoke
    end
  end

  task :prepare => [:environment] do
    require 'lib/data_marshal'
    require 'lib/downloader'
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

    restart_search_service

    puts "* Done"
  end

  desc "Fetch state from production server and install it locally"
  task :fetch => :prepare do
    source = SETTINGS.url + "export.data"
    #IK# source = "http://localhost:3000/export.data" # Only for testing
    target = "export.data"

    puts "* Downloading #{source}..."
    Downloader.download(source, target)

    puts "* Replacing data..."
    DataMarshal.restore(target)

    restart_search_service

    puts "* Migrating database..."
    Rake::Task['db:migrate'].invoke

    puts "* Done"
  end
end
