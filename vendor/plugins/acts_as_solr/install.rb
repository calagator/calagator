require 'fileutils'

def install(file)
  puts "Installing: #{file}"
  target = File.join(File.dirname(__FILE__), '..', '..', '..', file)
  FileUtils.cp File.join(File.dirname(__FILE__), file), target
  dir_to_rename = File.dirname(__FILE__) + '/../trunk'
  FileUtils.mv(dir_to_rename, File.dirname(__FILE__) + '/../acts_as_solr') if File.exists? dir_to_rename
end

install File.join( 'config', 'solr.yml' )
