namespace :db do
  desc "Download a copy of the remote production database and replace the loca development database"
  task :fetch => :environment do
    # FIXME display warnings??
    
    def bn(v); File.basename(v); end

    require 'lib/database_yml_reader'
    d = DatabaseYmlReader.read
    source = SETTINGS.url + "export.sqlite3"
    current = d.database
    backup = current + ".bak"
    replacement = current + ".replacement"

    puts "Backing up '#{bn current}' to '#{bn backup}'..."
    cp current, backup

    puts "Downloading '#{source}' to '#{bn replacement}'..."
    Downloader.download(source, replacement)

    puts "Swapping '#{bn replacement}' to '#{bn current}'..."
    mv replacement, current

    puts "Done"
  end
end
