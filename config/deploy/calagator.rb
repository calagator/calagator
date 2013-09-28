set :theme, "calagator"

 set :scm, "git"
 set :branch, "master" unless variables[:branch]
 set :repository,  "git://github.com/calagator/calagator.git"
 set :deploy_via, :remote_cache

#set :scm, "git"
#set :repository,  "."
#set :deploy_via, :copy
#set :copy_cache, true
#set :copy_exclude, ['.git', 'log', 'tmp', '*.sql', '*.diff', 'coverage.info', 'coverage.info', 'coverage', 'public/images/members', 'public/system', 'tags', 'db/remote.sql', 'db/*.sqlite3', '*.swp', '.*.swp']
#default_run_options[:pty] = true

set :deploy_to, "/var/www/calagator"
set :host, "calagator.org"
set :user, "calagator"

role :app, host
role :web, host
role :db,  host, :primary => true
default_run_options[:pty] = true
