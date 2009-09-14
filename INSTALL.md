Calagator
=========


Setup
-----

To use Calagator, you'll need to:

  1. [Install git](http://git-scm.com/) 1.6.x, a distributed version control system. Read the [Github Git Guides](http://github.com/guides/home) to learn how to use *git*.
  2. [Install Ruby](http://www.ruby-lang.org/), a programming language. You can use MRI Ruby 1.8.6, MRI Ruby 1.8.7, or [Phusion REE (Ruby Enterprise Edition)](http://rubyenterpriseedition.com/). Your operating system may already have Ruby installed or offer it as a prebuilt package.
  3. [Install RubyGems](http://rubyforge.org/projects/rubygems/) 1.3.x, a tool for managing software packages for Ruby. If you already have `rubygems` installed, you may need to update it by running `gem update --system` as root or an administrator.
  4. [Install SQLite3](http://www.sqlite.org/), a database engine. Your operating system may already have Ruby installed or offer it as a prebuilt package.
  5. [Install Ruby on Rails](http://rubyonrails.org/), a web development framework. You should run `gem install rails -v 2.3.4 --no-ri --no-rdoc` as root or an administrator.
  6. [Install Java](http://www.java.com/getjava) 1.6.x, a programming language used to run the Solr search server.

Additional, but out of date, instructions can be found at http://code.google.com/p/calagator/wiki/DevelopmentSoftware


Checkout
--------

To get the Calagator source code:

  1. Follow the **Setup** instructions above.
  2. Run `git clone git://github.com/calagator/calagator.git` or equivalent, which will create a `calagator` directory with the source code. Go into this directory and run the remaining commands from there.


Configuration
-------------

To configure Calagator:

  1. Follow the **Checkout** instructions above.
  2. Initialize your database, run `rake db:migrate db:test:prepare`
  3. Optionally add a geocoding key so maps will display, follow the instructions in the checkout at `config/geocoder_api_keys.yml.example` and get the key from http://code.google.com/apis/maps/signup.html


Development
-----------

To run Calagator in development mode:

  1. Follow the **Configuration** instructions above.
  2. Start the *Solr* search server by running `rake solr:start`
  3. Start the *Ruby on Rails* web application by running `./script/server` (UNIX) or `ruby script/server` (Windows).
  4. Open a web browser to http://localhost:3000/ to use the development server
  5. Read the [Rails Guides](http://guides.rubyonrails.org/) to learn how to develop a Ruby on Rails application.
  6. When done, stop the *Ruby on Rails* server `script/server` by pressing **CTRL-C** and stop *Solr* by running `rake solr:stop`.


Customization
-------------

If you want to customize your Calagator, do NOT just start modifying files in `app`, `public` and `themes/default`. Please read the instructions in `themes/README.txt` for how to use the theming system.


Security
--------

This application runs with insecure settings by default to make it easy to get started. These default settings include publicly-known cryptography keys that can allow attackers to gain admin privileges to your application. You should create a `config/secrets.yml` file with your secret settings if you intend to run this application on a server that can be accessed by untrusted users, read the [config/secrets.yml.sample](config/secrets.yml.sample) file for details.


Production
----------

Calagator.org runs on [Ubuntu Linux](http://ubuntu.com/), [Phusion REE (Ruby Enterprise Edition)](http://rubyenterpriseedition.com/) and [Phusion Passenger](http://www.modrails.com/).
