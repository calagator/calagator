= Themes

Themes let you customize the appearance of your Calagator instance. This directory contains the default theme and you'll add other themes into here.

== Setup

You need to do a few things to tell your server what theme it's using:

1. Pick a name for your theme, such as "mysite".
2. Tell your server what theme it should use by creating a configuration file, e.g. put "mysite" into the "config/theme.txt" file. This file will not exist unless you create it. You probably shouldn't add this file to version control because it's a run-time server setting like your secrets file. Don't forget to deploy this file to your production server too.
3. You can also set or override the theme used through the "THEME" environment variable, e.g. "THEME=mysite script/server". You will typically not want to do this because creating the "config/theme.txt" file is so easy.
4. Restart your Calagator instance if you created or changed the "config/theme.txt" file. However, once it's restarted, any changes you make within your theme will be reloaded automatically if you're using the default Rails "development" environment.

== Creating a theme

You need to create the actual theme:

1. Copy the default theme to create your own, e.g. copy "themes/default" to "themes/mysite" to create a new "mysite" theme. You should add the files in this directory to version control for your Calagtor instance's fork.
2. Edit the theme's settings to specify where your server is, what it's called and such, e.g. edit the "themes/mysite/settings.yml" file. The default theme's settings file is full of comments that will explain how to change it.
3. Your Calagator instance loads the theme's settings on startup, so if you change them, you will need to restart the instance.

== Customizing content

You need to customize some content in your theme:

* "themes/YOUR_THEME/views/site/about.html.erb" -- Describe in detail what your site is about, who runs it, how to use it, etc.
* "themes/YOUR_THEME/views/site/_appropriateness.html.erb" -- Describe what is appropriate content for your site, this message will be shown on the "Add event" and "Import event(s)" pages.
* "themes/YOUR_THEME/views/site/_description.html.erb" -- Describe briefly what your site is about in the sidebar on the homepage.

== Maintaining compatibility

You should try to maintain compatibility between your custom theme and future Calagator releases. If you're running only stable releases, please read the CHANGES.md entries mentioning "[THEME]" because they will describe new features and changes to the theming system that you may need to incorporate into your theme. If you're running development releases, e.g. pulling from the "master" branch, then you should pay close attention to commits that mention "THEME" in them, and may also want to view changes made to the "default" theme by running "git log -p themes/default/".

== Future

We recognize that putting complex logic into the theme is a bad idea. Unfortunately, this was the easiest way to build it and works well enough. In the future, we'd like to redo the theming from scratch so that the logic lives in the app and the theme just displays the data provided to it using a well-defined API. This probably won't happen any time soon though, so if you'd like to either do this work or sponsor it, please get in touch.
