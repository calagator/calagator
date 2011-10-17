Running Calagator on Heroku
===========================

[Heroku](http://heroku.com/) is a service that provides a way to run Ruby on Rails applications like Calagator for free or cheap.

Warning
-------

The ability to run Calagator on Heroku is very new and relies on experimental code. This documentation may not be complete and will change as we make progress with this. Please take the time to report problems, suggestions and corrections to the [calagator-development mailing list](http://groups.google.com/group/calagator-development) so we can make this work for you and others.

Setup
-----

To setup your copy of Calagator to run on Heroku:

* Checkout the source code and the `with_ruby192` branch:

        git clone git://github.com/calagator/calagator.git
        cd calagator
        git checkout with_ruby192

* Create a new branch for your Heroku-specific changes:

        git checkout -b heroku

* Register an account at [Heroku](http://heroku.com/).

* Initialize your Heroku application:

        heroku create

* Install Ruby 1.9.2. You should probably use [RVM](http://beginrescueend.com/) and run:

        rvm install 1.9.2

* If using RVM, create a gemset and use it:

        rvm gemset create calagator
        rvm use 1.9.2@calagator

* Install [PostgreSQL](http://www.postgresql.org/). Your OS may already provide easy-to-use pre-built libraries, e.g. on Ubuntu or Debian:

        sudo apt-get install postgresql

* Install the Heroku gem:

        gem install heroku

* Install the Bundler gem:

        gem install bundler

* If using RVM, install some additional libraries in a special way:

        gem install linecache19 -- --with-ruby-include=$rvm_path/src/${RUBY_VERSION?}
        gem install ruby-debug19 -- --with-ruby-include=$rvm_path/src/${RUBY_VERSION?}

* Configure your Rails app to use PostgreSQL by copying the sample and editing the authentication:

        cp config/database~postgresql.sample.yml config/database.yml

* Install dependencies and create a Bundle:

        bundle

* Edit your `.gitignore`, remove these lines, and commit it to your `heroku` branch:

        Gemfile.lock
        config/database.yml
        config/secrets.yml
        config/geocoder_api_keys.yml

* Create and commit all the above files to your `heroku` branch, see the `INSTALL.md` for instructions on how to create each of these.

* Edit your theme and ensure that it doesn't do caching, e.g. edit `themes/default/views/layouts/application.html.erb` and change `:cache => true` to `:cache => false`. Commit these changes to your `heroku` branch.

* You should now be able to run the app locally and access it as [http://localhost:3000/](http://localhost:3000/):

        rails server

Deployment
----------

Once you've confirmed that the stack works, you should now be able to deploy your app to Heroku:

	    git push --force heroku heroku:master
        heroku rake db:migrate

Your app should now be available! If the site fails to load, run `heroku logs` to try to identify the problem. If you're not sure how to fix the problem, please include the backtrace from the logs to help us figure out a solution.
