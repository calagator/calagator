# Initializes theme support by extending some of the core Rails classes
require 'patches/actionview_ex'
require 'patches/actioncontroller_ex'
require 'patches/actionmailer_ex'
require 'patches/routeset_ex'

ActionController::Base.send(:include, ThemeSupport::ControllerExtensions)
ActionMailer::Base.send(:include, ThemeSupport::ControllerExtensions)

# Add the tag helpers for rhtml and, optionally, liquid templates
require 'helpers/rhtml_theme_tags'

# Commented out to remove the message
# "Liquid doesn't seem to be loaded...  uninitialized constant Liquid"

#begin
#   require 'helpers/liquid_theme_tags'
#rescue
#   # I guess Liquid isn't being used...
#   STDERR.puts "Liquid doesn't seem to be loaded... #{$!}"
#end
