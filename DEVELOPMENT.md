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

3. Initialize your database by running:

        bundle exec rake app:db:migrate app:db:test:prepare

    If you like, you can also generate some sample data with

        bundle exec rake app:db:seed

4. At this point, you should be set up to run Calagator's test suite:

        bundle exec bin/rails spec

5. You're now ready to start up Calagator in `development` mode, which automatically reloads code as you change it:

        bundle exec bin/rails server

   If all went according to plan, you should be able to access your running Calagator at: [http://localhost:3000](http://localhost:3000).

    To stop the server, press `CTRL-C`.

    If you're running calagator in a Vagrantbox, add `-b 0.0.0.0` to the bundle exec command to handle requests from the host OS:

    `bundle exec bin/rails server -b 0.0.0.0`

## Running the tests

#### Run the main test suite

    `bundle exec rake spec`

#### Run appraisal test suite

    `bundle exec appraisal install && bundle exec appraisal rake spec`

## Building the calagator gem locally

By default the project relies on the released version of the calagator gem on rubygems.org.
To test and develop the gem locally you need to build it locally. 

### 1. Update the gem version (for local testing)

To test your own gem you'll want to give it a local version, generally dont commit this version.

Update version number in /lib/calendar/version.rb

### 2. Build the gemspec and locally install the gem

    `gem build calagator.gemspec && gem install calagator`

### 3. Go to another folder to test the gem

You'll need to come out of your project folder.
I made a folder called 'ruby_2_6' for this to test against ruby 2.6 projects for example.

   `bundle exec calendar new yourappname`

This process tests the gem works, that the new app gems build and that migrations work and more.
If any errors come up, fix these are repeat from step 1.
### 4. Activley test the gem built app

Go in the new directory.

    `bin/rails serve`

Do a quick test by making a new event that is on tomorrow, save it and then check it's on the homepage.