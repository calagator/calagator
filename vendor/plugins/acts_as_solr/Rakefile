require 'rubygems'
require 'rake'
require 'rake/testtask'

Dir["#{File.dirname(__FILE__)}/lib/tasks/**/*.rake"].sort.each { |ext| load ext }

desc "Default Task"
task :default => [:test]

desc 'Runs the tests'
task :test do
  ENV['RAILS_ENV'] = "test"
  require File.dirname(__FILE__) + '/config/environment'
  puts "Using " + DB
  %x(mysql -u#{MYSQL_USER} < #{File.dirname(__FILE__) + "/test/fixtures/db_definitions/mysql.sql"}) if DB == 'mysql'
  
  Rake::Task["test:migrate"].invoke
  Rake::Task[:test_units].invoke
end

desc "Unit Tests"
 Rake::TestTask.new('test_units') do |t|
  t.pattern = "test/unit/*_test.rb"
  t.verbose = true
end
