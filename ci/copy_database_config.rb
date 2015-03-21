require 'fileutils'

which_config = "ci/database.#{ENV['DB'] || 'sqlite'}.yml"

puts "Copying database configuration for CI: #{which_config}"
FileUtils.cp which_config, 'spec/dummy/config/database.yml'
