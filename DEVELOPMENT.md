# Developing Calagator

## Prerequisites

Before you start, you will need to:

* [Install git](http://git-scm.com/), a distributed version control system. Read the GitHub ["Set Up Git"](https://help.github.com/articles/set-up-git) article to learn how to use git.

  *Some additional resources for familiarizing yourself with git:*
    * [Pro Git ebook](http://git-scm.com/book)
    * [Try Git](https://try.github.io/levels/1/challenges/1)
    * [Git Immersion](http://gitimmersion.com/)
    * [Think Like a Git](http://think-like-a-git.net/)

* [Install Ruby](http://www.ruby-lang.org/), a programming language. You can use MRI Ruby 2.0+, or Rubinius 2.0+. Your operating system may already have it installed or offer it as a pre-built package. You can check by typing `ruby -v` in your shell or console.
* [Install SQLite3](http://www.sqlite.org/), a database engine. Your operating system may already have it installed or offer it as a pre-built package. You can check by typing `sqlite3 -version` in your shell or console.

## Getting Started

1. Get the source code: From your command line, run `git clone https://github.com/calagator/calagator.git`, which will create a `calagator` directory with the source code. Change into this directory (`cd calagator`) and run the remaining commands from there.
2. Install Bundler-managed gems, (the actual libraries that this application uses, like Ruby on Rails) by running `bundle install`. This may take a long time to complete.
3. Generate a dummy host application. This is a new Rails application that includes Calagator from your current checkout of the code and is used for running tests:

        bundle exec bin/calagator new spec/dummy --dummy

4. Initialize your database by running:

        bin/rake app:db:migrate app:db:test:prepare

    If you like, you can also generate some sample data with 

        bin/rake app:db:seed

5. At this point, you should be set up to run Calagator's test suite:

        bin/rspec

6. You're now ready to start up Calagator in `development` mode, which automatically reloads code as you change it:

        spec/dummy/bin/rails server
        
   If all went according to plan, you should be able to access your running Calagator at: [http://localhost:3000](http://localhost:3000).

    To stop the server, press `CTRL-C`.

