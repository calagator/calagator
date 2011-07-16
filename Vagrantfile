# You can override settings in this file by creating a `Vagrantfile.local`
# file, see the `VAGRANT.md` file for instructions.
overrides = "#{__FILE__}.local"
if File.exist?(overrides)
    eval File.read(overrides)
end

Vagrant::Config.run do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # The url from where the 'config.vm.box' box will be fetched if it
  # doesn't already exist on the user's system.
  config.vm.box_url = "http://opscode-vagrant-boxes.s3.amazonaws.com/ubuntu10.04-gems.box"

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = File.basename(config.vm.box_url, ".box")

  # Assign this VM to a host only network IP, allowing you to access it
  # via the IP.
  if (defined?(NFS) && NFS) || defined?(ADDRESS)
    config.vm.network defined?(ADDRESS) ? ADDRESS : "33.33.31.13"
  end

  # Forward a port from the guest to the host, which allows for outside
  # computers to access the VM, whereas host only networking does not.
  config.vm.forward_port "http", 80, defined?(HTTP_PORT) ? HTTP_PORT : 8080
  config.vm.forward_port "rails", 3000, defined?(RAILS_PORT) ? RAILS_PORT : 8000

  # Share an additional folder to the guest VM. The first argument is
  # an identifier, the second is the path on the guest to mount the
  # folder, and the third is the path on the host to the actual folder.
  config.vm.share_folder "vagrant", "/vagrant", ".", :nfs => defined?(NFS) ? NFS : false

  # Enable provisioning with chef solo, specifying a cookbooks path (relative
  # to this Vagrantfile), and adding some recipes and/or roles.
  config.vm.provision :chef_solo do |chef|
    chef.cookbooks_path = "vagrant/cookbooks"
    chef.add_recipe "vagrant"
  end
end
