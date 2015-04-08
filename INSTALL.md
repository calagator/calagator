Calagator
=========

Requirements
-----

* Linux or Mac OSX operating system.
* [Ruby](http://www.ruby-lang.org/), a programming language. Calagator is compatible with Ruby 2.0, and greater. Your operating system may already have it installed or offer it as a pre-built package. You can check by typing `ruby -v` in your shell or console.
* A database, like [SQLite3](http://www.sqlite.org/), [MySQL](http://www.mysql.com/), or [PostgreSQL](http://www.postgresql.org/). Your operating system may already have it installed or offer it as a pre-built package. You can check by typing `sqlite3 -version`, `mysql --version`, or `psql --version` in your shell or console.


Installing Calagator inside an existing Rails app?
-----

Calagator is compatible with Rails 4.0, and greater.

Add the gem to your Rails application's `Gemfile`

```
gem 'calagator'
```

Then run the install generator in the terminal

```
rails generate calagator:install
```


Creating a new Calagator site from scratch?
-----

Install the `calagator` gem

```
gem install calagator
```

Run the installer to generate a new Calagator application

```
calagator new ~/path/to/new/calagator/app
```


Additional Setup
-----

Calagator's settings be configured via a generated initializer file at `config/initializers/calagator.rb`. Please see that file for more details.

*Optional:*
  * Start the search service if needed. See the **[Search engine](#search_engine)** section for details.


Customization
-------------

If you want to customize your Calagator instance, you can override the templates, JavaScript, and CSS provided by the engine. See [http://guides.rubyonrails.org/engines.html#overriding-views] for more information.


API Keys
--------

The application uses a number of API keys to communicate with external services.

* Google Maps: To use Google's geocoder, and to use Google to display maps, you must get an API key.  See the `config/initializers/calagator.rb` file for details.
* Meetup.com: To import events from Meetup.com, you need an API key. See the `config/initializers/calagator.rb` file for details.


Mapping
-------

Calagator can use a number of map tile providers when displaying maps. This can be configured in `config/initializers/calagator.rb`.


Search engine
-------------

You can specify the search engine to use in your `config/initializers/calagator.rb` file:

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
