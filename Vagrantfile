# You can override settings in this file by creating a `Vagrantfile.local`
# file, see the `VAGRANT.md` file for instructions.
overrides = "#{__FILE__}.local"
if File.exist?(overrides)
    eval File.read(overrides)
end

Vagrant.configure(2) do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  config.vm.box = "ubuntu/trusty64"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine.
  config.vm.network "forwarded_port", guest: 80, host: defined?(HTTP_PORT) ? HTTP_PORT : 8080
  config.vm.network "forwarded_port", guest: 3000, host: defined?(RAILS_PORT) ? RAILS_PORT : 8000

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Use more memory so Bundler works.
  config.vm.provider "virtualbox" do |vb|
    vb.memory = defined?(MEMORY) ? MEMORY : 1024
  end

  # avoid tty errors in ubuntu
  # https://github.com/mitchellh/vagrant/issues/1673
  config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"
  config.vm.provision :shell, :path => "vagrant/provision.sh"
end
