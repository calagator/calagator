# Override the settings here by creating a "Vagrantfile.local" file. You can currently use it to override the portforwarding by using commands like:
#  HTTP_PORT  = 9999 # Forwarding for VM's port 80
#  RAILS_PORT = 8888 # Forwarding for VM's port 3000
overrides = "#{__FILE__}.local"
if File.exist?(overrides)
    eval File.read(overrides)
end

Vagrant::Config.run do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "calagator"

  # The url from where the 'config.vm.box' box will be fetched if it
  # doesn't already exist on the user's system.
  config.vm.box_url = "http://opscode-vagrant-boxes.s3.amazonaws.com/ubuntu10.04-gems.box"

  # Forward a port from the guest to the host, which allows for outside
  # computers to access the VM, whereas host only networking does not.
  config.vm.forward_port "http", 80, defined?(HTTP_PORT) ? HTTP_PORT : 8080
  config.vm.forward_port "rails", 3000, defined?(RAILS_PORT) ? RAILS_PORT : 8000

  # Share an additional folder to the guest VM. The first argument is
  # an identifier, the second is the path on the guest to mount the
  # folder, and the third is the path on the host to the actual folder.
  config.vm.share_folder "vagrant", "/vagrant", "."

  # Enable provisioning with chef solo, specifying a cookbooks path (relative
  # to this Vagrantfile), and adding some recipes and/or roles.
  config.vm.provision :chef_solo do |chef|
    chef.cookbooks_path = "vagrant/cookbooks"
    chef.add_recipe "vagrant"
  end
end
