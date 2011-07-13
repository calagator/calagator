APPDIR = "/vagrant" # Application directory
USER = "vagrant"      # User that owns files

# Update package list, but only if stale
execute "update-apt" do
  timestamp = "/root/.apt-get-updated"
  command "apt-get update && touch #{timestamp}"
  only_if do
    ! File.exist?(timestamp) || (File.stat(timestamp).mtime + 60*60) < Time.now
  end
end

# Add gems to PATH
file "/etc/profile.d/rubygems1.8.sh" do
  content "PATH=/usr/lib/ruby/gems/1.8/bin:$PATH"
end

# Install packages
for name in %w[screen tmux elinks build-essential libcurl4-openssl-dev libsqlite3-dev libxml2 libxml2-dev libxslt1.1 libxslt1-dev]
  package name
end

# Install gems
for name in %w[bundler]
  gem_package name
end

# Install bundle
execute "install-bundle" do
  cwd APPDIR
  command "bundle check || bundle --local || bundle update"
end

# Setup database
execute "setup-db" do
  user USER
  cwd APPDIR
  command "bundle exec rake db:create:all db:migrate db:test:prepare"
end

# Start server
execute "start-server" do
  user USER
  cwd APPDIR
  command "./script/server --port 3000 --daemon"
end
