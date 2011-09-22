Activation Calendar
===================

Setup
-----
* Install git.  (`apt-get install git` on Ubuntu).
* Download the code from https://github.com/PDXHub/activation_calendar.
    git clone git://github.com/PDXHub/activation_calendar.git
* Note that you probably need some prerequisite packages (related to xml and ssl).  See the requirements for RVM and Rails.
* Follow the Calagator setup instructions in INSTALL.md, except that:
  * Download [RVM](http://beginrescueend.com/rvm/install), and use that to get rails 3. I followed these instructions for getting requirements: http://stuffingabout.blogspot.com/2011/04/installing-rails-3-on-ubuntu-1104.html.  Your mileage may vary; please update this file if you have better instructions.
  * Instead of downloading calagator code, you have already downloaded Activation Calendar.
* Follow the Development instructions (but instead of running `./scripts/server`, run `rails server`).  You should now see the site running at http://localhost:3000

Verify Setup
------------
Run 'rails db' and it drops you in sqlite3 command, where the `.database` and `.tables` sqlite3 commands show that you have some tables in the development.sqlite3 database (which, prior to runnining `bundle exec rake db:migrate db:test:prepare` in the Calagator development instructions was empty):
    shark@eos:~/dev/activation_calendar(activate_theme)$ rails db
    SQLite version 3.7.4
    Enter ".help" for instructions
    Enter SQL statements terminated with a ";"
    sqlite> .database
    seq  name             file
    ---  ---------------  ----------------------------------------------------------
    0    main             /home/shark/dev/activation_calendar/db/development.sqlite3
    sqlite> .tables
    events             sources            tags               venues
    schema_migrations  taggings           updates            versions



Development Conventions
-----------------------
* Implement new features on feature branches in git (ex: `git checkout -b full-calendalar` ... hackhackhack... `git commit; git checkout master; git merge full-calendar`).

See Also
--------
 * Logo files are in dropbox.  Lindsay can share with you if necessary.
 * Issues / stories are in Pivotal Tracker. https://www.pivotaltracker.com/projects/365511

Submitting code changes
-----------------------
Once you have made changes to the code, you can do a pull request.
Or, if you have push permission, you can run:
    git push origin name-of-your-feature-branch
