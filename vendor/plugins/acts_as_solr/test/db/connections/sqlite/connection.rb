require 'logger'
ActiveRecord::Base.logger = Logger.new("debug.log")

ActiveRecord::Base.establish_connection(
  :adapter  => "sqlite3",
  :encoding => "utf8",
  :database => File.join(File.dirname(File.expand_path(__FILE__)), '..', '..', 'test.db')
)
