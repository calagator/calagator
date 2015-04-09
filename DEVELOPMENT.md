Development
-----------

To work on the calagator engine itself, you must clone the project, then generate a dummy app to run the tests in.

  ```bash
  git clone https://github.com/calagator/calagator.git
  cd calagator
  bundle install # install calagator's dependencies
  bundle exec bin/calagator new spec/dummy --dummy # generate a new dummy app at spec/dummy
  bundle exec rake app:db:create app:db:migrate app:db:test:prepare app:db:seed # initialize your database
  bundle exec rake spec # run the tests to make sure everything is working
  ```

To see the site in your web browser:
  * Start the web server: `cd spec/dummy && rails server`
  * Open a web browser to <http://localhost:3000/> to use the development server

Lastly, you may wish to read the [Rails Guides](http://guides.rubyonrails.org/) to learn how to develop a Ruby on Rails application.
