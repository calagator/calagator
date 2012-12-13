require 'uri'
require 'erb'

ENV['RAILS_ENV']  = (ENV['RAILS_ENV'] || 'development').dup
SOLR_PATH = "#{File.dirname(File.expand_path(__FILE__))}/../solr" unless defined? SOLR_PATH

unless defined? SOLR_PORT
  SOLR_PORT =
    ENV['PORT'] || \
    if File.exists?(Rails.root+'/config/solr.yml')
      # Via 'config/solr.yml' file
      config = YAML::load(ERB.new(File.read(Rails.root+'/config/solr.yml')).result)
      if config[Rails.env]['port']
        # Via 'port' attribute
        config[Rails.env]['port'].to_i
      else
        # Via 'url' attribute
        url = config[Rails.env]['url']
        uri = URI.parse(url)
        uri.port
      end
    else
      # Fallback to default
      case ENV['RAILS_ENV']
      when 'test' then 8981
      when 'production' then 8983
      else 8982
      end
    end
end

if ENV['RAILS_ENV'] == 'test'
  DB = (ENV['DB'] ? ENV['DB'] : 'mysql') unless defined? DB
  MYSQL_USER = (ENV['MYSQL_USER'].nil? ? 'root' : ENV['MYSQL_USER']) unless defined? MYSQL_USER
  require File.join(File.dirname(File.expand_path(__FILE__)), '..', 'test', 'db', 'connections', DB, 'connection.rb')
end
