Using Vagrant for development
=============================

[Vagrant](http://vagrantup.com/) is a tool used by this project to provide you with a complete, working copy of the development environment. Using Vagrant will make it easier and faster to begin working on this project than if you were to try to set everything up yourself. Vagrant works by creating a virtual machine -- an isolated operating system that runs within your normal operating system. This virtual machine has been specially prepared to include everything needed to develop and run the application.

Setup
-----

Setup Vagrant and its dependencies:

1. Install Ruby: [http://www.ruby-lang.org/](http://www.ruby-lang.org/)
2. Install Rubygems: [http://rubygems.org/pages/download](http://rubygems.org/pages/download)
3. Install VirtualBox: [http://www.virtualbox.org/](http://www.virtualbox.org/)
4. Install Vagrant:

        gem install vagrant

Usage
-----

Working with a Vagrant environment requires interacting with your local operating system AND the virtual machine. You will use your local machine to access the web application at [http://localhost:8000/](http://localhost:8000/), edit files, and do version control. You will use your virtual machine to run `bundle exec rake` and other commands that need the development environment.

Use Vagrant by issuing the commands below. The `local%` and `virtual%` in the commands are just indicators to show which machine to enter commands into, you shouldn't actually type them -- thus `local% pwd` means that you should run `pwd` on your local machine.

**Start** the virtual machine, which will take some time to download the first time:

    local% vagrant up

**Access** the application running on the virtual machine by visiting -- it won't be running until you start it though:

    http://localhost:8000/

**SSH** into the virtual machine and go into the directory containing the application:

    local% vagrant ssh

**Run** the application on the virtual machine, it will be accessible on [http://localhost:8000/](http://localhost:8000/):

    local% vagrant ssh
    virtual% rails server

**Test** the application within the virtual machine:

    local% vagrant ssh
    virtual% bundle exec rake

**Reload** the virtual machine, needed if you changed the `Gemfile` or `config` files, or used a revision control command that updated them:

    local% vagrant reload

**Suspend** the virtual machine, quickly pausing it when you're done and freeing up memory:

    local% vagrant suspend

**Resume** the virtual machine, quickly resuming a suspended virtual machine:

    local% vagrant resume

**Destroy** the virtual machine if you don't need it any more and want to free up disk space -- don't worry, you can always `vagrant up` to recreate it later:

    local% vagrant destroy

Advanced settings
-----------------

### Virtual machine

You can customize some settings on your virtual machine by creating a `Vagrantfile.local` file. This file is local to your computer and should not be added to revision control.

The overrides are written in Ruby and included by the `Vagrantfile` if found. These overrides are applied when you start a virtual machine with `vagrant up` or any time you run `vagrant reload`.

Below are the supported overrides:

* Forward the virtual machine's port 80 to the local machine's port 8080:

        HTTP_PORT  = 8080

* Forward the virtual machine's port 3000 to the local machine's port 8000:

        RAILS_PORT = 8000

* Share files from the local machine to the virtual machine using NFS, which is much faster than the default sharing mechanism. Unfortunately, there are a few gotchas. You must provision the virtual machine initially without NFS so the NFS client can be installed, then you can enable NFS and run `vagrant reload` so you can begin using it. You must be running a UNIX-like operating system as your local machine, have an NFS server installed, and have `root` access via `sudo` for Vagrant to automatically configure NFS sharing.

        NFS = true

* Set the virtual machine's IP address to `33.33.31.13`, which is useful if you want to SSH into the virtual machine by IP, rather than using `vagrant ssh`. If you're not using overrides to set the address or enable NFS, the address will be randomly assigned by VirtualBox.

        ADDRESS = "33.33.31.13"

* Set the amount of memory to dedicate to the virtual machine to 512 megabytes. The appropriate amount will depend on how much memory you have available versus how much processes within the virtual machine need. In general, running `bundler` or `gem` in the virtual machine will require at least 512 megabytes:

        MEMORY = 512

### Provisioning

You can customize your virtual machine by creating a `vagrant/cookbooks/vagrant/recipes/local.rb` file. This file is local to your computer and should not be added to revision control.

This file can contain any valid Chef recipe code, and will be applied when a virtual machine is first created using `vagrant up` or any time you run `vagrant reload`. This custom code will be run after all the other operating system packages have been installed, but before Bundler is run -- see `vagrant/cookbooks/vagrant/recipes/default.rb` for additional context.

For example, you could add the following to install the `emacs` package on your virtal machine:

    package "emacs"
