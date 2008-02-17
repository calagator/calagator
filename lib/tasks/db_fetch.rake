namespace :db do
  desc "Download a copy of the remote production database and replace the loca development database"
  task :fetch do
    sh "scp sumomo:/var/www/calagator/db/production.sqlite3 db/development.sqlite3"
  end
end
