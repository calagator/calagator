APPDIR = "/vagrant" # Application directory
USER = "vagrant"      # User that owns files

# Change directory to /vagrant after doing a `vagrant ssh`.
execute "update-profile-chdir" do
  profile = "~vagrant/.profile"
  command %{printf "\nif shopt -q login_shell; then cd #{APPDIR}; fi" >> #{profile}}
  not_if "grep -q 'cd #{APPDIR}' #{profile}"
end

# Update package list, but only if stale
execute "update-apt" do
  timestamp = "/root/.apt-get-updated"
  command "apt-get update && touch #{timestamp}"
  only_if do
    ! File.exist?(timestamp) || (File.stat(timestamp).mtime + 60*60) < Time.now
  end
end

# Remove obsolete file
file "/etc/profile.d/rubygems1.8.sh" do
  action :delete
end

# Add gems to PATH, use "zz-" prefix to ensure this runs after box's "vagrantruby.sh".
file "/etc/profile.d/zz-rubygems1.8.sh" do
  content "export PATH=`gem env path`:$PATH"
end

# Remove conflicting packages
for name in %w[irb ruby-dev]
  package name do
    action :remove
  end
end

# Install packages
for name in %w[nfs-common git-core screen tmux elinks build-essential libcurl4-openssl-dev libsqlite3-dev libxml2 libxml2-dev libxslt1.1 libxslt1-dev]
  package name
end

# Install gems
gem_package "bundler"
gem_package "rake" do
  version "0.8.7"
end

# Fix permissions on homedir
execute "chown -R #{USER}:#{USER} ~#{USER}"

# Run the contents of the "vagrant/cookbooks/vagrant/recipes/local.rb" file if present. This optional file can contain additional provisioning logic that shouldn't be part of the global setup. For example, if you're using the "Gemfile.local" to install special gems, you'd use this "local.rb" to install their dependencies.
local_recipe = File.join(File.dirname(__FILE__), "local.rb")
if File.exist?(local_recipe)
  eval File.read(local_recipe)
end

# Install bundle
execute "install-bundle" do
  cwd APPDIR
  command "su vagrant -l -c 'bundle check || bundle --local || bundle'"
end

# Setup database
execute "setup-db" do
  cwd APPDIR
  command "su vagrant -l -c 'bundle exec rake db:create:all db:migrate db:test:prepare'"
end
