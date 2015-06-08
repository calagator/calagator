# Changes

Conventions used in this document:

  * [!] - Important note regarding some change.
  * [SETTING] - Changed setting structure, see the `themes/README.txt` file for details.
  * [MIGRATION] - Change schema, run `bundle exec rake db:migrate` to apply.

## Change Log

List of Calagator releases and changes, with the latest at the top:

  * [master]
  * v1.0.0 - **[!] Major Changes [!]**
    * [!] This release completely changes the way in which Calagator is distributed, moving from a standalone Rails app to a [Rails engine](http://guides.rubyonrails.org/engines.html). Instead of deploying Calagator instance from a modified version of this code, Calagator is now included as a gem within a new Rails app. Please review the updated installation instructions in INSTALL.md.
    * If you are upgrading a site based on an earlier version of Calagator, please [drop us a line](http://groups.google.com/group/calagator-development/). We've recently upgraded [calagator.org](http://calagator.org) and can help to point you in the right direction.
    * [THEME] The theme system has been removed, favoring the [view overriding](http://guides.rubyonrails.org/engines.html#overriding-views) functionality provided by Rails engines.
This works much the same way as the previous theme system, allowing any Calagator view to be overridden by creating a file at the corresponding path within your app's `app/views/calagator` directory.
    * [SETTING] The YAML-based settings and secrets mechanisms have been replaced with an initializer inside the host application. See INSTALL.md for details.
    * [MIGRATION] Database migrations are now installed into your host application.

### Pre-1.0

Prior to version 1.0, Calagator was distributed as a standalone Rails app instead of an engine. Some additional labels are relevant in these changes that are not used above.

  * [THEME] - Changed theme structure, see the `themes/README.txt` file for details.
  * [SECRETS] - Changed secrets structure, see the `INSTALL.md` file for details.
  * [DEPENDENCY] - Changed dependencies.

  * v0.20150320
    * [!] Dropped support for Ruby 1.8.7, and 1.9.3. Use Ruby 2.0+.
    * Switched from outdated v2 Google Maps to a more flexible leaflet-based mapping system.
      * [!] New mapping settings have been added to secrets.yml
        If you wish to keep using Google as your map provider, you'll need to set your provider and add an API key to secrets.yml.
      * [!] The "venues_google_map_options" setting in settings.yml has been renamed to venues_map_settings.
      * [!] Loading Google API keys from config/geocoder_api_keys.yml has been deprecated. Use config/secrets.yml instead.
      * [THEME] References to the #google_map div in stylesheets should be changed to #map.
      * [THEME] Theme authors need to require the mapping javascript files in the layout:
        Add `<%= javascript_include_tag *mapping_js_includes %>` just before your application javascript_include_tag.
    * Updated to Rails 3.2.21
    * Rewrote deployment scripts using [Capistrano 3](http://capistranorb.com)
    * Streamlined navigation, collapsing "Overview" and "Browse Events"
    * Added the ability to lock individual events from editing to prevent vandalism
    * Added a unified admin tool list (/admin) with optional password protection. Includes changelog, duplicate squashing, and event locking.
    * Added prettier tag URLs (e.g. /events/tag/ruby, and /venues/tag/office)
    * Added friendlier error pages with a confused alligator
    * Added tag icons
    * Added database seeds to ease development
    * Fixed search loading and reindexing
    * Squashed wiggly bugs
    * Gloriously increased test coverage
    * Copiously refactored, improved code style, and swept up unused code
    * Updated vagrant configuration to Ubuntu 14.04 and Ruby 2.1
  * v0.20131020
    * We now use the Rails 3.2 asset pipeline to compile assets.
      * [!][THEME] Theme maintainers need to make a few small changes when upgrading.
        See https://github.com/calagator/calagator/wiki/Asset-Pipeline-Theme-Upgrade for details.
    * Improved venue search, backed by by SQL or Sunspot.
      * [!] If you're running a Calagator instance using Sunspot for search, you'll want to run `rake sunspot:reindex` to index your venues.
    * Added Twitter and Facebook share buttons to event pages
    * Added ability to export all events at a given venue to iCalendar
    * Fixed Google geocoder: v2 was deprecated, using v3 now
    * Assed microformats2 markup to event pages
    * Removed reliance on the rails default /:controller/:action/:id route
    * [DEPENDENCY] Upgraded formtastic and other dependencies
    * Updated spam blacklist.
  * v0.20130717
    * [DEPENDENCY] Upgraded to rails 3.2.13.
    * Fixed #30: Relax markdown emphasis parsing to avoid adding emphasis to words_containing_underscores.
    * Fixed #22 and #33: avoid double-output of cache block for filtered events.
    * Fixed #35: Use 'medium' git log format for footer version number.
    * Fixed #36, #37: Limit the number of links in event descriptions to three.
    * Fixed Google Code issue #280: Strip whitespace from venue fields.
    * Fixed #38: Fixed display of events with no end time
    * Added Schema.org support to event markup.
    * Updated spam blacklist.
  * v0.20121111
    * Updated specs to use the new RSpec 2.11.
    * Update and increase use of factories.
    * Improved TravisCI configuration
    * Updated spam blacklist.
  * v0.20120906
    * [DEPENDENCY] Upgraded to Rails 3.2.8.
    * [DEPENDENCY] Upgraded other external dependencies to support Rails 3.2.
    * [DEPENDENCY] Added database_cleaner.
    * [MIGRATION] Fix venues latitude/longitude on MySQL to specify precision.
    * Fixed event form autocomplete.
    * Fixed search by tag feed/subscription links.
    * Fixed, refactored and improved specs and factories: dependent examples, nesting, fixtures, factories, etc.
    * Fixed #updated_at, which may have been breaking iCal refreshes.
    * Fixed timezone parsing behavior.
    * Improved duplicate detection.
    * Removed obsolete 'export' routes, which are throwing exceptions when hit.
    * Added a rake task up update counter caches.
    * Added `rake spec:db:all` and others to run tests against all or specific databases.
    * Updated spam blacklist.
  * v0.20120810
    * [DEPENDENCY] Upgraded to Rails 3.0.17, for security fixes.
    * [DEPENDENCY] Upgraded several external dependencies.
    * [DEPENDENCY] Removed outdated acts_as_solr plugin.
    * Improved TravisCI configuration: Added Ruby 1.9.2, postgresql, sqlite3, and mysql to the test matrix.
  * v0.20120709
    * [!] This release drops support for 'acts_as_solr' search backend.  Please migrate to the 'sunspot' backend instead.
    * [DEPENDENCY] Upgraded most external dependencies.
    * [MIGRATION] Remove obsolete tables and columns that may have been left behind.
    * Improved compatibility with Ruby 1.9.x.
    * Improved tag cloud implementation and styling.
    * Improved ATOM output.
    * Fixed issues with CacheObserver.
    * Fixed ordering when searching by tag
    * Fixed handling of unknown formats in requests
    * Reworked date forms to better handle editing and cloning.
    * Switched to Capistrano for deployment and data downloading.
    * Improved specs.
    * Updated spam blacklist.
    * Added configuration for TravisCI to test on 1.8.7 and 1.9.3
  * v0.20120518
    * Improved Facebook source parser code to increase clarity and use new REST URLs.
    * Updated spam blacklist with new terms and improved its search efficiency.
    * Added escaping and error handling to `rake log:archive`.
  * v0.20120215
    * Added links to about page for subscribing to calendar and feed.
    * Fixed map display under Ruby 1.9 and corrected map float behavior.
    * Fixed Google Code issue #457: blacklist should also be read from a local configuration.
    * Fixed Google Code issue #458: Changed about page to use relative links for links within calagator.
    * Fixed Gemfile to load "ruby-debug" using :platform declarations.
    * Fixed Vagrant to add workaround for Windows mounting '/var/cache/apt'.
  * v0.20111027
    * [DEPENDENCY] Upgraded Rails to 3.0.10.
    * Added support for Ruby 1.9.2.
    * Added PostgreSQL support to Vagrant environment.
    * Fixed Github issues #6 & #7: Markdown links and references broken.
    * Fixed Event#to_clone to also include :venue_details.
  * v0.20111021
    * [!] This should be the final release based on Ruby on Rails 2.x, all future releases will be based on Rails 3.x.
    * [DEPENDENCY] Upgraded to Rails 2.3.12.
    * [MIGRATION] Added venue details so organizers can specify per-event information like room number, access code, etc.
    * [THEME] Added mobile CSS stylesheet for friendlier experience on smaller screens.
    * Updated Upcoming importer to work around invalid UTC dates emitted by current API.
    * Updated Plancast importer to use the new, official JSONP API.
    * Updated Meetup importer to use the new, official API if a key is available. See instructions in `INSTALL.md` file.
    * Update robot exclusion rules to allow Google Calendar to subscribe to filtered searches.
    * Updated iCalendar exporter to include venue address and source URL.
    * Added "opensearch" to let browsers use Calagator as a search provider.
    * Added Vagrant support, allowing easy setup of a development environment. See instructions in `VAGRANT.md` file.
  * v0.20110603
    * [DEPENDENCY] Added `bundler` for installing dependencies and isolating from unwanted versions of gems. See `INSTALL.md`  for usage information.
    * [MIGRATION] Added fields to Venues: access notes, "has public wifi" flag, and "is closed" flag.
    * [THEME] Added file to describe appropriate content for a Calagator instance, e.g. "Portland-area tech events". If not present, a reasonable default will be displayed.
    * [SETTING] Removed `tz` field. You now only need to set `timezone`. If theme still has `tz`, it will be ignored.
    * Fixed documentation to explain how to create a theme, setup a `development` environment, and install a `production` server.
    * Fixed export to Google Calendar, which could fail if the event's description was long or truncated at a bad place.
    * Fixed exception notification to send emails with Rails 2.3.10 and newer, submitted fix as patch to `theme_support` plugin maintainer.
    * Fixed exception notification to set `From:` in a helpful way so that these can be replied to by those subscribed to notifications.
    * Fixed previewing of a new event with a new venue, it would throw an exception.
    * Fixed duplicate squashing to not throw exceptions if called with blank arguments, like when hit by a bot.
    * Fixed version refresh system, used on event/venue edit forms, to switch between versions of a record.
    * Added parsers to import Plancast and Meetup events.
    * Added Plancast machine tag to connect Calagator events with their external Plancast counterparts and display Plancast attendees on the event page.
    * Added ePDX machine tag to connect events with their ePDX groups.
    * Added JSON and KML exports to the venues listing.
    * Improved iCalendar importing system to use the better `RiCal` library.
    * Improved venues listing to show the latest and most popular venues, search venues, display map, etc.
    * Improve display of URLs on various pages by truncating them if they're long.
    * Improved imported sources so they can be deleted and remove their associated event and venue records.
    * Improved recent changes rollback system to display messages, be able to rollback the `create` events, and redirect to appropriate pages.
    * Improved event form to accept URL parameters, so it can be pre-populated with desired values.
    * Improved venue destroy to prevent someone from removing a venue that still has events, to avoid orphaning these.
    * Improved new venue form to accept simplified address and not request longitude/latitude.
  * v0.20110301
    * [!] This version adds support for specifying the search engine to use for local data. The new default is `sql`, which requires no configuration or setup to work. If you have an existing Calagator instance and want to continue using ActsAsSolr, edit your `config/secrets.yml` file and specify `search_engine: acts_as_solr`. See the "Search engine" section of the `INSTALL.md` file for details.
    * [SECRETS] Added `search_engine` field for specifying search engine.
    * [DEPENDENCY] Upgraded to latest stable releases of Ruby on Rails and other libraries.
    * [DEPENDENCY] Added optional `sunspot` search engine, which provides the best search results and is more reliable, efficient and speedy than `acts_as_solr`.
    * Fixed importing to support Upcoming's mobile site, the only one many users can now use.
    * Fixed performance of duplicate checking and squashing interfaces.
    * Fixed exceptions thrown when filtering events by invalid dates.
    * Improved dependencies so production environment doesn't need testing libraries.
    * Added `sql` search engine, which is used by default and requires no configuration or setup.
  * v0.20101108
    * [!] Fixed searching, run `bundle exec rake solr:rebuild_index` to rebuild your search index to take advantage of the improvements for matching by: exact words, fuzzy word match, words that had punctuation in or adjacent to them, and tags.
    * [DEPENDENCY] Added RiCal library.
    * [DEPENDENCY] Fixed "environment.rb" to specify exact versions of known-good gems, because new versions of gems have been released that have bugs or aren't backwards compatible.
    * Fixed search sorting and improved title displays.
    * Fixed iCalendar exports, they now include timezone and location.
    * Improved iCalendar exports, they now include a sequence field.
    * Improved `bundle exec rake data:fetch` to display download progress if programs like `curl` and `wget` are installed.
    * Added machine tags, to link Calagator entries to those on external services.
    * Added tag cloud for displaying popular tags.
  * v0.20100302
    * Fixed `bundle exec rake gems:install`, some required gems weren't being installed.
    * Fixed `bundle exec rake solr:start`, the Net::HTTP syntax changed in recent versions of Ruby.
    * Fixed `bundle exec rake db:dump` and `bundle exec rake db:restore`, the environment changed in recent versions of Rails.
    * Fixed the recent changes listing to display changes made to deleted record.
    * Eliminated alert emails notifying admin that a form was submitted without a valid authentication token, which is almost always a spam bot.
    * Improved event form so that the end date is set to the start date if the start date is changed to be after the end date, and displayed highlight to alert user of the modification.
    * Improved event form so that the end time is offset from the start time if the start time is changed, and displayed highlighted to alert the user of the modification
  * v0.20091223
    * [SECRETS] Added entry for setting custom Upcoming API key.
    * Added Upcoming API-based event importer, hopefully resolving long-standing problems caused by them frequently changing their invalid iCalendar output.
    * Fixed export to Google Calendar.
    * Fixed to support tags that start with numbers.
    * Fixed recent changes to not fail if showing create AND delete on same page.
    * Improved iCalendar export to mark very long events as all-day events.
    * Added "preview" feature to the event add and edit forms.
    * Added "more events" link to bottom of site's events overview.
  * v0.20091001
    * Added feature to "clone", create a new event based on an existing one, to the event's sidebar.
    * Improved recent changes, added title for each record and reorganized columns to read from left-to-right.
  * v0.20090928
    * [DEPENDENCY] + [MIGRATION] Implemented new data versioning and management system that can track and rollback deletes and more, replaces `acts_as_versioned` with `PaperTrail`.
    * Fixed how Solr determines what port to connect to, it will now always check the `config/solr.yml`.
  * v0.20090914
    * [DEPENDENCY] Upgraded to Ruby on Rails 2.3.x and updated many gems.
    * [THEME] Upgraded `theme_support`, which expects layouts to be in `MYTHEME/views/layouts` rather than `MYTHEME/layouts`.
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
