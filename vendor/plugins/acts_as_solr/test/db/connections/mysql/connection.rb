require 'logger'
ActiveRecord::Base.logger = Logger.new("debug.log")

ActiveRecord::Base.establish_connection(
  :adapter  => "mysql",
  :username => MYSQL_USER,
  :encoding => "utf8",
  :database => "actsassolr_tests"
)

