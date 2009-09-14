Changes
=======

Key
---

  * [THEME] - Changed theme structure, see `themes/README.txt` for details.
  * [SETTING] - Changed setting structure, see `themes/README.txt` for details.
  * [MIGRATION] - Change schema, run `rake db:migrate` to apply.
  * [DEPENDENCY] - Changed dependencies.

Changes
-------

List of Calagator stable releases and changes, with the latest at the top:

  * Next
    * [DEPENDENCY] Upgraded to Ruby on Rails 2.3.x and updated many gems.
    * [THEME] Upgraded theme_support, which expects layouts to be in `MYTHEME/views/layouts` rather than `MYTHEME/layouts`.
    * [SETTING] Added `SECRETS.administrator_email` with email to send errors, extracted it from `config/initalizer/exception_notification_setup.rb`.
    * [MIGRATION] Added PaperTrail plugin to provide complete version tracking of all changes, including deletes.
    * Added recent changes tracking and rollback using PaperTrail.
    * Added new README.md, INSTALL.md, CONTRIBUTORS.md, and CHANGES.md files.
  * v0.2009031
    * [SETTING] Fixed timezone handling so that the application, added new `timezone` setting.
    * [THEME] Fixed layout and added an `ie.6` stylesheet.
    * Fixed duplicate checking to eliminate infinite loops and link items to their progenitor.
    * Fixed times in Upcoming imports, which violate the iCalendar standard. 
    * Fixed search sort labels.
  * v0.20090503
    * Fixed error caused by removal of Time.today from RubyGems 1.3.2 and above.
    * Fixed initialization error by delaying loading of tagging extensions till tables are created.
    * Added easily customizable `config/database.yml`, see file for usage.
    * Added initial MySQL and PostgreSQL ports with many SQL fixes, however, only SQLite3 is currently recommended.
