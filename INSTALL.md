Calagator
=========


Setup
-----

To use Calagator, you'll need to:

  * [Install git](http://git-scm.com/) 1.5.x or newer, a distributed version control system. Read the [Github Git Guides](http://github.com/guides/home) to learn how to use *git*.
  * [Install Ruby](http://www.ruby-lang.org/), a programming language. You can use MRI Ruby 1.8.6, MRI Ruby 1.8.7, or [Phusion REE (Ruby Enterprise Edition)](http://rubyenterpriseedition.com/). Your operating system may already have Ruby installed or offer it as a prebuilt package.
  * [Install RubyGems](http://rubyforge.org/projects/rubygems/) 1.3.x, a tool for managing software packages for Ruby. If you already have `rubygems` installed, you may need to update it by running `gem update --system` as root or an administrator.
  * [Install SQLite3](http://www.sqlite.org/), a database engine. Your operating system may already have Ruby installed or offer it as a prebuilt package.
  * [Install Bundler](http://gembundler.com/), a Ruby dependency management tool. You should run `gem install bundler` as root or an administrator.
  * Checkout the Calagator source code. Run `git clone git://github.com/calagator/calagator.git` or equivalent, which will create a `calagator` directory with the source code. Go into this directory and run the remaining commands from there.
  * Install Bundler-managed gems, the actual libraries that this application uses, like Ruby on Rails. You should run `bundle update`, which may take a long time to complete.
  * Optionally specify the theme to use, see the **Customizing** section for details.
  * Optionally setup API keys for external services so that maps will be displayed, see the **API Keys** section for details.
  * Start the search service if needed, see the **Search engine** section for details.


Development
-----------

To run Calagator in `development` mode, which automatically reloads code as you change it:

  * Follow the **Setup** instructions above.
  * Initialize your database, run `bundle exec rake db:migrate db:test:prepare`
  * Start the *Ruby on Rails* web application by running `./script/server` (UNIX) or `ruby script/server` (Windows).
  * Open a web browser to <http://localhost:3000/> to use the development server
  * Read the [Rails Guides](http://guides.rubyonrails.org/) to learn how to develop a Ruby on Rails application.
  * When done, stop the *Ruby on Rails* server `script/server` by pressing `CTRL-C`.


Production
----------

To run Calagator in `production` mode, which runs more quickly, but doesn't reload code:

  * Follow the **Setup** instructions above. Don't forget to do things like create the theme and secrets files.
  * Initialize your database, run `bundle exec rake RAILS_ENV=production db:migrate`
  * Run `bundle exec rake clear` to clear your cache after updating your application's code.
  * Setup a production web server using [Phusion Passenger](http://www.modrails.com/), [Thin](http://code.macournoyer.com/thin/), [Rainbows](http://rainbows.rubyforge.org/), etc. These will be able to serve more users more quickly than `script/server`.

The Calagator.org site runs on [Ubuntu Linux](http://ubuntu.com/), [Phusion REE (Ruby Enterprise Edition)](http://rubyenterpriseedition.com/) and [Phusion Passenger](http://www.modrails.com/).


Customization
-------------

If you want to customize your Calagator, do NOT just start modifying files in `app`, `public` and `themes/default`. Please read the instructions in `themes/README.txt` for how to use the theming system.


Security and secrets.yml
------------------------

This application runs with insecure settings by default to make it easy to get started. These default settings include publicly-known cryptography keys that can allow attackers to gain admin privileges to your application. You should create a `config/secrets.yml` file with your secret settings if you intend to run this application on a server that can be accessed by untrusted users, read the [config/secrets.yml.sample](config/secrets.yml.sample) file for details.


API Keys
--------

The application uses a number of API keys to communicate with external services.

* Yahoo! Upcoming: To import events from Upcoming, the application can use a public key, but for production use, you should really get and use your own API key. See the `config/secrets.yml.sample` file's `upcoming_api_key` section for details.

* Google Maps: To display Google maps, you must get an API key. For details, see the `config/geocoder_api_keys.yml.example` for details.


Search engine
-------------

You can specify the search engine to use in your `config/secrets.yml` file:

### sql

Default search engine which uses SQL queries. Requires no additional setup, dependencies or service. Does not provide relevance-based sorting. Provides substring matches.

### sunspot

Optional search engine that uses the Sunspot gem. Requires additional setup, dependencies and service. Provides relevance-based sorting. Does not provide substring matches.

To use, you will need to [install Java 1.6.x](http://www.java.com/getjava), a programming language used to run the search service.

You will then need to initially populate your records by running commands like:

    bundle exec rake RAILS_ENV=production sunspot:solr:start
    bundle exec rake RAILS_ENV=production sunspot:reindex:calagator

You can start the Solr search service a command like:

    bundle exec rake RAILS_ENV=production sunspot:solr:start

You can stop the Solr search service a command like:

    bundle exec rake RAILS_ENV=production sunspot:solr:stop

### acts_as_solr

Optional search engine that uses the `acts_as_solr` gem. Requires additional setup, dependencies and service. Provides relevance-based sorting. Provides substring matches. However, has severe performance problems that may slow down creating and editing records.

To use, you will need to [install Java 1.6.x](http://www.java.com/getjava), a programming language used to run the search service.

You will then need to initially populate your records by running a command like:

    bundle exec rake RAILS_ENV=production solr:rebuild_index

You can start the Solr search service a command like:

    bundle exec rake RAILS_ENV=production solr:start

You can stop the Solr search service a command like:

    bundle exec rake RAILS_ENV=production solr:stop


Feedback wanted
---------------

Is there something wrong, unclear or outdated in this documentation? Please get in touch so we can make it better. If you can contribute improved text, we'd really appreciate it.
