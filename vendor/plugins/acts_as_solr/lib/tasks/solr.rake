require 'rubygems'
require 'rake'
require 'net/http'
require 'active_record'
require "#{File.dirname(__FILE__)}/../../config/environment.rb"

namespace :solr do

  desc 'Starts Solr. Options accepted: RAILS_ENV=your_env, PORT=XX. Defaults to development if none.'
  task :start do
    begin
      n = Net::HTTP.new('localhost', SOLR_PORT)
      n.request_head('/').value 

    rescue Net::HTTPServerException #responding
      puts "Port #{SOLR_PORT} in use" and return

    rescue Errno::ECONNREFUSED #not responding
      Dir.chdir(SOLR_PATH) do
        pid = fork do
          #STDERR.close
          exec "java -Dsolr.data.dir=solr/data/#{ENV['RAILS_ENV']} -Djetty.port=#{SOLR_PORT} -jar start.jar"
        end
        sleep(5)
        File.open("#{SOLR_PATH}/tmp/#{ENV['RAILS_ENV']}_pid", "w"){ |f| f << pid}
        puts "#{ENV['RAILS_ENV']} Solr started successfully on #{SOLR_PORT}, pid: #{pid}."
      end
    end
  end
  
  desc 'Stops Solr. Specify the environment by using: RAILS_ENV=your_env. Defaults to development if none.'
  task :stop do
    fork do
      file_path = "#{SOLR_PATH}/tmp/#{ENV['RAILS_ENV']}_pid"
      if File.exists?(file_path)
        File.open(file_path, "r") do |f| 
          pid = f.readline
          Process.kill('TERM', pid.to_i)
        end
        File.unlink(file_path)
        Rake::Task["solr:destroy_index"].invoke if ENV['RAILS_ENV'] == 'test'
        puts "Solr shutdown successfully."
      else
        puts "Solr is not running.  I haven't done anything."
      end
    end
  end
  
  desc 'Remove Solr index'
  task :destroy_index do
    raise "In production mode.  I'm not going to delete the index, sorry." if ENV['RAILS_ENV'] == "production"
    if File.exists?("#{SOLR_PATH}/solr/data/#{ENV['RAILS_ENV']}")
      Dir[ SOLR_PATH + "/solr/data/#{ENV['RAILS_ENV']}/index/*"].each{|f| File.unlink(f)}
      Dir.rmdir(SOLR_PATH + "/solr/data/#{ENV['RAILS_ENV']}/index")
      puts "Index files removed under " + ENV['RAILS_ENV'] + " environment"
    end
  end
end
