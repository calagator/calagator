set :theme, "calagator"

set :scm, "git"
set :branch, "master" unless variables[:branch]
set :repository,  "git://github.com/calagator/calagator.git"
set :deploy_to, "/var/www/calagator"
set :host, "calagator.org"
set :user, "calagator"

set :deploy_via, :remote_cache
role :app, host
role :web, host
role :db,  host, :primary => true
default_run_options[:pty] = true
