# Templates using these extensions won't try to look for corresponding layouts.

ActionController::Base.exempt_from_layout 'css.erb'
ActionController::Base.exempt_from_layout 'atom.erb'
ActionController::Base.exempt_from_layout 'atom.builder'
ActionController::Base.exempt_from_layout 'kml.erb'