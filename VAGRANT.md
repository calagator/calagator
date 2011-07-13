Using Vagrant for development
=============================

Vagrant is a tool that simplifies setup by providing you with a complete, working copy of the Calagator development environment. If you're new to Ruby, using Vagrant will be much easier than setting up the environment yourself. Vagrant works by creating a "virtual machine", an isolated operating system that runs within your normal operating system. This virtual machine has been specially prepared to include everything needed to develop and run the application.

Overview
--------

Working with Vagrant means interacting with your local operating system AND the virtual machine.

You'll use your local machine to access the web application at [http://localhost:8000/](http://localhost:8000/), edit files, and do version control.

You'll use your virtual machine to run `bundle exec rake` and other commands that need the development environment.

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

Use Vagrant by issuing the commands below. The `local%` and `virtual%` mentioned in the commands are just indicators to show which machine to enter commands into, you shouldn't actually type them -- thus `local% pwd` means that you should run `pwd` on your local machine.

prefixes are meant to indicate what machine you're on

**Start** the virtual machine, which will take some time to download the first time:

    local% vagrant up

**Access** the application running on the virtual machine by visiting:

    http://localhost:8000/

**SSH** into the virtual machine and go into the directory containing the application:

    local% vagrant ssh
    virtual% cd /vagrant

**Test** the application within the virtual machine:

    local% vagrant ssh
    virtual% cd /vagrant
    virtual% bundle exec rake

**Reload** the virtual machine, needed if you changed the `Gemfile` or `config` files, or used a revision control command that updated them:

    local% vagrant reload

**Suspend** the virtual machine, quickly pausing it when you're done and freeing up memory:

    local% vagrant suspend

**Resume** the virtual machine, quickly resuming a suspended virtual machine:

    local% vagrant resume

**Destroy** the virtual machine if you don't need it any more and want to free up disk space -- don't worry, you can always `vagrant up` to recreate it later:

    local% vagrant destroy
