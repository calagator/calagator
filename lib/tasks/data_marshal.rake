namespace :data do
  require 'lib/data_marshal'

  desc "Dumps state to FILE, defaults to DBNAME.TIMESTAMP.data"
  task :dump do
    filename = DataMarshal.dump(ENV["FILE"])
    puts "* Dumped data to #{filename}"
  end

  desc "Restores state from FILE"
  task :restore do
    filename = ENV["FILE"] or raise ArgumentError, "The data:restore task requires a FILE argument to define which file to restore from, e.g. 'rake FILE=current.data data:restore'"
    DataMarshal.restore(filename)
    puts "* Restored state from #{filename}"
  end
end
