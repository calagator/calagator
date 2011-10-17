Running Calagator on Heroku
===========================

[Heroku](http://heroku.com/) is a service that provides a way to run Ruby on Rails applications like Calagator for free or cheap.

Warning
-------

The ability to run Calagator on Heroku is very new and relies on experimental code. This documentation may not be complete and will change as we make progress with this. Please take the time to report problems, suggestions and corrections to the [calagator-development mailing list](http://groups.google.com/group/calagator-development) so we can make this work for you and others.

Also, take heed of these issues:

* Do not publish your `heroku` branch, it contains secret information such as your API keys. In the future, we hope to use Heroku's config variables to avoid committing secret information as files to the repository.
* Do not use multiple Heroku dynos becuase the code uses file system caching. In the future, we hope to offer a configuration option to choose the caching mechanism: none (slow, but works with multiple dynos), file-system (fast, but doesn't support multiple dynos) and memcache (fast, supports multiple dynos, but requires additional setup).

Minimal setup
-------------

If you want to just deploy Calagator to Heroku without needing to run it locally:

* Checkout the source code, go into the checkout directory, and use the `with_heroku` branch:

        git clone git://github.com/calagator/calagator.git
        cd calagator
        git checkout with_heroku

* Create a new branch for your Heroku-specific changes:

        git checkout -b heroku

* Register an account at [Heroku](http://heroku.com/).

* Install the Heroku gem:

        gem install heroku

* Initialize your Heroku application:

        heroku create

* Follow the instructions in the `INSTALL.md` file to create these files:

        config/theme.txt
        config/secrets.yml
        config/geocoder_api_keys.yml

* Add and commit the above files to your `heroku` branch:

        git add config/theme.txt config/secrets.yml config/geocoder_api_keys.yml
        git commit config/theme.txt config/secrets.yml config/geocoder_api_keys.yml

* Go to the **Deployment** section below to deploy the application to Heroku.

Full setup
----------

If you want to setup a development server able to run the Heroku code locally, which will significantly simplify your ability to work with the code:

* Checkout the source code and the `with_heroku` branch:

        git clone git://github.com/calagator/calagator.git
        cd calagator
        git checkout with_heroku

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

* Configure your Rails app to use PostgreSQL, create a `config/database~custom.yml` file. You can use the `config/database~postgresql.sample.yml` as a sample.

* Install dependencies and create a Bundle:

        bundle

* If your `Gemfile.lock` changes after running `bundle`, commit it to your `heroku` branch:

* Follow the instructions in the `INSTALL.md` file to create these files:

        config/theme.txt
        config/secrets.yml
        config/geocoder_api_keys.yml

* Add and commit the above files to your `heroku` branch:

        git add config/theme.txt config/secrets.yml config/geocoder_api_keys.yml
        git commit config/theme.txt config/secrets.yml config/geocoder_api_keys.yml

* You should now be able to run the app locally and access it as [http://localhost:3000/](http://localhost:3000/):

        rails server

* Go to the **Deployment** section below to deploy the application to Heroku.

Deployment
----------

Once you've confirmed that the stack works, you should now be able to deploy your app to Heroku:

    git push --force heroku heroku:master
    heroku rake db:migrate

Your app should now be available! If the site fails to load, run `heroku logs` to try to identify the problem. If you're not sure how to fix the problem, please include the backtrace from the logs to help us figure out a solution.
