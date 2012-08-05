Running Calagator on Heroku
===========================

[Heroku](http://heroku.com/) is a service that provides an easy way to run Ruby on Rails applications like Calagator for free or cheap. We recognize that running your own server and building a production Ruby web server can be a challenge, and hope that Heroku can make it easier for more communities to run their own Calagator.

Warnings
--------

You should be aware of some issues about deploying Calagator to Heroku:

* This process is new and relies on experimental code. This documentation may not be complete and will change as we improve the process. Please take the time to report problems, suggestions and corrections to the [calagator-development mailing list](http://groups.google.com/group/calagator-development) so we can make this work for you and others. We care. Really.
* Do not publish your `heroku` branch to the public, it contains secret information such as your API keys. In the future, we hope to use Heroku's config variables to avoid committing secret information as files to the repository.
* Do not use multiple Heroku dynos because the code currently uses file system caching. In the future, we hope to offer a configuration option to choose the caching mechanism: none (slow, but works with multiple dynos), file-system (fast, but doesn't support multiple dynos) and `memcached` (fast, supports multiple dynos, but requires additional setup).
* You can only use the `sql` search engine. In the future, we hope to offer the ability to use our better `sunspot` search engine with Heroku's `solr` service.
* Maps aren't shown and geocoding doesn't work. We're not sure why, but are working on it.

Common setup
------------

You need do the following before you can deploy a Calagator to Heroku:

* Register an account at [Heroku](http://heroku.com/).

* Install Git, a version control system used to get the Calagator source code and interact with Heroku. Your operating system may already provide an easy way to install this, e.g. on Ubuntu you can run `sudo apt-get install git-core`. Downloads are available at [http://git-scm.com/download](http://git-scm.com/download).

* Install Ruby, the programming language used by Calagator and Heroku's utilities: [http://www.ruby-lang.org/en/downloads/](http://www.ruby-lang.org/en/downloads/). If you plan to put in the extra effort to run Calagator on your own computer for development (described in the **Development setup** section below), you *must* use Ruby 1.9.2 and should probably use the [RVM installer](https://rvm.beginrescueend.com/rvm/install/) if possible.

* Install Rubygems, a system for downloading and loading Ruby libraries: [https://rubygems.org/pages/download](https://rubygems.org/pages/download).

* Open a terminal and use it to run the rest of the commands in this section.

* Checkout the Calagator source code, go into the checkout directory, and use the `with_heroku` branch:

        git clone git://github.com/calagator/calagator.git
        cd calagator
        git checkout with_heroku

* It's important that you run all commands in this section from a terminal within the `calagator` directory created above. So if you close the terminal, you can continue on by just opening another one and running `cd DIR` where `DIR` is the path to this `calagator` directory.

* Create a new `heroku` branch for your Heroku-specific changes:

        git checkout -b heroku

* Install Heroku's utilities:

        gem install heroku

* Initialize your Heroku application:

        heroku create

* Add a Heroku database, e.g.:

        heroku addons:add heroku-postgresql:dev

* **WARNING**: This default free database only allows 10,000 rows of data, [read about how to buy more](https://addons.heroku.com/heroku-postgresql).

* Make the Heroku database your default:

        heroku pg:promote `heroku addons | grep HEROKU_POSTGRESQL | awk '{ print $2 }'`

* Follow the instructions in the `INSTALL.md` file to create these files:

        config/theme.txt
        config/secrets.yml
        config/geocoder_api_keys.yml

* Add and commit the above files to your `heroku` branch:

        git add config/theme.txt config/secrets.yml config/geocoder_api_keys.yml
        git commit config/theme.txt config/secrets.yml config/geocoder_api_keys.yml

Next, you can follow the instructions in either the:

* **Deployment** section below to deploy your application to Heroku.
* **Development setup** section below to setup a Calagator development environment so you can run Calagator on your own computer.

Development setup
-----------------

You can do run the Calagator development environment on your computer so you can more easily do theming and additional work on your application:

* Open a terminal and `cd` into the `calagator` directory created when you did the `git` checkout, and run all of the commands from there.

* If using RVM:

        # Install Ruby
        rvm install 1.9.3

        # Create a gemset
        rvm gemset create calagator

        # Use the new interpreter and gemset
        rvm use 1.9.3@calagator

        # Record your settings
        rvm --rvmrc --create 1.9.3@calagator

* Install [PostgreSQL](http://www.postgresql.org/), the database used by Heroku. Your operating system may already provide an easy way to install this, e.g. on Ubuntu you can run `sudo apt-get install postgresql`.

* Install the Heroku gem:

        gem install heroku

* Install the Bundler gem:

        gem install bundler

* Configure the Calagator application to use PostgreSQL, by creating a `config/database~custom.yml` file and adding your database credentials there. You can use the `config/database~postgresql.sample.yml` as a reference.

* Install the Calagator application's dependencies:

        bundle

* If your `Gemfile.lock` is modified after running `bundle` -- check by running `git status Gemfile.lock` -- then you should commit it to your `heroku` branch:

* You should now be able to run the Calagator application on your computer and access it as [http://localhost:3000/](http://localhost:3000/) by running:

        rails server

Deployment
----------

After following the instructions in the **Common setup** section, you should now be able to deploy your app to Heroku:

    git push --force heroku heroku:master
    heroku run bundle exec rake db:migrate
    heroku restart

Your app should now be available! If the site fails to load, run `heroku logs` to try to identify the problem. If you're not sure how to fix the problem, please include the backtrace from the logs to help us figure out a solution.

Updating
--------

You should periodically incorporate the fixes and improvements made to Calagator into your `heroku` branch:

    git checkout heroku && git fetch origin && git merge origin/with_heroku

You can now redeploy the application by following the instructions in the **Deployment** section above.
