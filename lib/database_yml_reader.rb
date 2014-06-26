# Reads the Rails +database.yml+ configuration file and provides access to its
# data structures.

require 'erb'
require 'yaml'
require 'ostruct'

class DatabaseYmlReader
  def self.read(path = 'config/database.yml', env = (ENV['RAILS_ENV'] || 'development'))
    raise "Can't find database configuration at: #{path}" unless File.exist?(path)
    databases = YAML.load(ERB.new(File.read(path)).result)
    database = databases.fetch(env) { raise "Can't find database configuration for environment '#{env}' in: #{path}" }
    OpenStruct.new(database)
  end
end

