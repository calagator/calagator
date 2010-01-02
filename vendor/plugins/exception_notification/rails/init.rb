require "action_mailer"

require "super_exception_notifier/custom_exception_classes"
require "super_exception_notifier/custom_exception_methods"
require "super_exception_notifier/helpful_hashes"
require "super_exception_notifier/git_blame"
require "super_exception_notifier/deprecated_methods"
require "super_exception_notifier/hooks_notifier"
require "super_exception_notifier/notifiable_helper"

require "exception_notifier_helper" unless defined?(ExceptionNotifierHelper)
require "exception_notifier" unless defined?(ExceptionNotifier)
require "exception_notifiable" unless defined?(ExceptionNotifiable)
require "notifiable" unless defined?(Notifiable)

Object.class_eval do
  include Notifiable
end

#It appears that the view path is auto-added by rails... hmmm.
#if ActionController::Base.respond_to?(:append_view_path)
#  puts "view path before: #{ActionController::Base.view_paths}"
#  ActionController::Base.append_view_path(File.join(File.dirname(__FILE__), 'app', 'views','exception_notifiable'))
#  puts "view path After: #{ActionController::Base.view_paths}"
#end
