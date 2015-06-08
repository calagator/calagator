# Installing Calagator

Calagator is distributed as a [Rails engine](http://guides.rubyonrails.org/engines.html), which is a type of Ruby gem that can be "mounted" inside of a Rails application to add functionality. In this document, we'll refer to the app that Calagator is mounted in as the *host application*.

## Requirements

Calagator requires Ruby 1.9.3 - 2.1.x, and a host application built on Rails 4 or newer.

## Running a site based on Calagator

If you're looking to build your own community calendar using Calagator, follow these instructions. If you're aiming to contribute code to Calagator itself, see the instructions in [DEVELOPMENT.md](https://github.com/calagator/calagator/blob/master/DEVELOPMENT.md).

### Getting Started

First, install the `calagator` gem:

    gem install calagator --pre
    
You can then use the `calagator` command to generate a new Rails application with Calagator installed:

    calagator new my_great_calendar
    cd my_great_calendar

You should now be able to start your calendar in development mode with:

    bin/rails server

If all went according to plan, you should be able to see your calendar at: [http://localhost:3000](http://localhost:3000).

To stop the server, press `CTRL-C`.

## Configuration

Calagator's settings can be configured by editing these files in your host application:

* `config/initializers/01_calagator.rb`
* `config/initializers/02_geokit.rb`

Please see these file for more details.

### API Keys

Calagator uses a number of API keys to communicate with external services.

* Google Maps: To use Google's geocoder, and to use Google to display maps, you must get an API key.  See `config/initializers/01_calagator.rb` and `config/initializers/02_geokit.rb` for details.

* Meetup.com: To import events from Meetup.com, you need an API key. See `config/initializers/01_calagator.rb` for details.

### Search engine

You can specify the search engine to use in `config/initializers/01_calagator.rb`:

#### SQL

This is the default search engine which uses SQL queries. This option requires no additional setup, dependencies, or service. It does not provide relevance-based sorting. It does provide substring matches.

#### Sunspot

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

<!--
## Customization

**TODO: engine CSS and view overrides, variables.scss, config.scss(?)**
-->

Feedback wanted
---------------

Is there something wrong, unclear, or outdated in this documentation? Please get in touch so we can make it better. If you can contribute improved text, we'd really appreciate it.