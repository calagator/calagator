Calagator
=========


Setup
-----

You will need to:

* [Install git](http://git-scm.com/), a distributed version control system. Read the GitHub ["Set Up Git"](https://help.github.com/articles/set-up-git) article to learn how to use git.

  *Some additional resources for familiarizing yourself with git:*
    * [Pro Git ebook](http://git-scm.com/book)
    * [Try Git](https://try.github.io/levels/1/challenges/1)
    * [Git Immersion](http://gitimmersion.com/)
    * [Think Like a Git](http://think-like-a-git.net/)


* [Install Ruby](http://www.ruby-lang.org/), a programming language. You can use MRI Ruby 1.9.3+, or Rubinius 2.0+. Your operating system may already have it installed or offer it as a pre-built package. You can check by typing `ruby -v` in your shell or console.
* [Install SQLite3](http://www.sqlite.org/), a database engine. Your operating system may already have it installed or offer it as a pre-built package. You can check by typing `sqlite3 -version` in your shell or console.
* [Install Bundler](http://gembundler.com/), a Ruby dependency management tool. You should run `gem install bundler` as root or an administrator after installing Ruby.
* Copy the source code. From your command line, run `git clone https://github.com/calagator/calagator.git`, which will create a `calagator` directory with the source code. Change into this directory (run `cd calagator`) and run the remaining commands from there.
* Install Bundler-managed gems, (the actual libraries that this application uses, like Ruby on Rails) by running `bundle install`. This may take a long time to complete.

*If you intend to run your own instance of Calagator:*

  * Follow the additional instructions in **[Security and secrets.yml](#security)**

*Optional:*
  * Specify the theme to use. See the **[Customization](#customization)** section for details.
  * Setup API keys for external services so that maps will be displayed, see the **[API Keys](#api_keys)** section for details.
  * Start the search service if needed. See the **[Search engine](#search_engine)** section for details.


Development
-----------

To run Calagator in `development` mode, which automatically reloads code as you change it:

  * Follow the **[Setup](#setup)** instructions above.
  * Initialize your database by running `bundle exec rake db:migrate db:test:prepare db:seed`
  * Start the *Ruby on Rails* web application by running `rails server` (UNIX) or `ruby script/rails /server` (Windows).
  * Open a web browser to <http://localhost:3000/> to use the development server
  * Read the [Rails Guides](http://guides.rubyonrails.org/) to learn how to develop a Ruby on Rails application.
  * To stop the *Ruby on Rails* server (e.g. `rails server`), press `CTRL-C`.


Production
----------

To run Calagator in `production` mode, which runs more quickly, but doesn't reload code:

  * Follow the **[Setup](#setup)** instructions above. Don't forget to [set up your secrets files](#security) and [customize your theme](#customization).
  * Set up a firewall to protect ports used by your search engine. See the **[Search engine](#search_engine)** section for details.
  * Initialize your database by running `bundle exec rake RAILS_ENV=production db:migrate`
  * Run `bundle exec rake clear` to clear your cache after updating your application's code.
  * Set up a production web server using [Phusion Passenger](https://www.phusionpassenger.com/), [Thin](http://code.macournoyer.com/thin/), [Unicorn](http://unicorn.bogomips.org/), [Rainbows](http://rainbows.bogomips.org/), etc. These will be able to serve more users more quickly than using the built-in server (e.g. `rails server`).
  * Run the following commands to compile core and theme-based assets into the `public/` directory:

    ```
    bundle exec rake assets:precompile
    bundle exec rake themes:create_cache
    ```

The Calagator.org site runs on [Ubuntu Linux](http://ubuntu.com/), [MRI Ruby](http://ruby-lang.org/) and [Phusion Passenger](https://www.phusionpassenger.com/).


Customization
-------------

If you want to customize your Calagator instance, do NOT just start modifying files in `app/`, `public/` and `themes/default`. Please read the instructions in `themes/README.txt` for how to use the theming system.


Security and secrets.yml
------------------------

This application runs with insecure settings by default to make it easy to get started. These default settings include publicly-known cryptography keys that can allow attackers to gain admin privileges to your application. You should create a `config/secrets.yml` file with your secret settings if you intend to run this application on a server that can be accessed by untrusted users. Read the [config/secrets.yml.sample](config/secrets.yml.sample) file for details.

Spam Blacklist
--------------

A default set of blacklist words is provided in `config/blacklist.txt`. You can create your own by adding a config/blacklist-local.txt file with one regular expression per line (see [config/blacklist.txt](config/blacklist.txt) for examples).

API Keys
--------

The application uses a number of API keys to communicate with external services.

* Google Maps: To use Google's geocoder, and to use Google to display maps, you must get an API key.  See [config/secrets.yml.sample](config/secrets.yml.sample) for details.

* Meetup.com: To import events from Meetup.com, you need an API key. See [config/secrets.yml.sample](config/secrets.yml.sample) for details.

Mapping
-------

Calagator can use a number of map tile providers when displaying maps. This can be configured in [config/secrets.yml](config/secrets.yml).


Search engine
-------------

You can specify the search engine to use in your [config/secrets.yml](config/secrets.yml) file:

### SQL

This is the default search engine which uses SQL queries. This option requires no additional setup, dependencies, or service. It does not provide relevance-based sorting. It does provide substring matches.

### Sunspot

This optional search engine uses the Sunspot gem. This option requires additional setup, dependencies, and service. It provides relevance-based sorting. It does not provide substring matches.

To use Sunspot, you will need to [install Java 1.6.x](http://www.java.com/getjava), a programming language used to run the search service.

You can start the Solr search service for local development with:

    bundle exec rake sunspot:solr:start

You will then need to initially populate your records by running:

    bundle exec rake sunspot:reindex:calagator

You can stop the Solr search service with:

    bundle exec rake sunspot:solr:stop

Calagator has tests that verify functionality against Solr automatically, if the tests find the service running; you'll see pending tests if Solr isn't found. To start a test instance of Solr, do:

    bundle exec rake RAILS_ENV=test sunspot:solr:start

You should set up a firewall to protect the ports utilized by the Solr search service. These ports are described in the [config/sunspot.yml](config/sunspot.yml) file.

Feedback wanted
---------------

Is there something wrong, unclear, or outdated in this documentation? Please get in touch so we can make it better. If you can contribute improved text, we'd really appreciate it.
