= Themes

This directory contains themes for this application. Each theme provides
settings for defining the application's behavior and styling to specify
it's appearance.

== Initialization

Themes are loaded during the startup process by first looking to see if
the name of a theme was specified in the "THEME" environmental variable,
else in the "config/theme.txt" file, else it falls back to the "default"
theme.

== Customizing

See the files in the "themes/default" directory to see the files
necessary to make a theme. See the "themes/default/settings.yml" file
for settings that define how the application should behave.

The "default" theme contains a simple theme that is easiest for you to
derive your own from, while the other themes provide more advanced
examples of what's possible.
