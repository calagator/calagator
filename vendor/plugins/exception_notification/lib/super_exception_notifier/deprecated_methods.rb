#Copyright (c) 2008-2009 Peter H. Boling of 9thBit LLC
#Released under the MIT license

module SuperExceptionNotifier
  module DeprecatedMethods
    @@namespacing = "Better namespacing to allow for Notifiable and ExceptionNotifiable to have similar APIs"
    @@rails2ruby = "An effort to make this a 'Ruby' Gem and not a stricly 'Rails' Gem"
    
    def http_error_codes
      deprecation_warning("http_error_codes", "error_class_status_codes")
      error_class_status_codes
    end

    def http_error_codes=(arg)
      deprecation_warning("http_error_codes", "error_class_status_codes")
      error_class_status_codes=(arg)
    end

    def rails_error_codes
      deprecation_warning("rails_error_codes", "error_class_status_codes", @@rails2ruby)
      error_class_status_codes
    end

    def rails_error_codes=(arg)
      deprecation_warning("rails_error_codes=", "error_class_status_codes=", @@rails2ruby)
      error_class_status_codes=(arg)
    end

    # Now defined in Object class by init.rb & Notifiable module,
    #   so we need to override them for with the controller settings
    def exception_notifier_verbose
      deprecation_warning("exception_notifier_verbose", "exception_notifiable_verbose", @@namespacing)
      exception_notifiable_verbose
    end
    def silent_exceptions
      deprecation_warning("silent_exceptions", "exception_notifiable_silent_exceptions", @@namespacing)
      exception_notifiable_silent_exceptions
    end
    def notification_level
      deprecation_warning("notification_level", "exception_notifiable_notification_level", @@namespacing)
      exception_notifiable_notification_level
    end
    def exception_notifier_verbose=(arg)
      deprecation_warning("exception_notifier_verbose=", "exception_notifiable_verbose=", @@namespacing)
      exception_notifiable_verbose = arg
    end
    def silent_exceptions=(arg)
      deprecation_warning("silent_exceptions=", "exception_notifiable_silent_exceptions=", @@namespacing)
      exception_notifiable_silent_exceptions = arg
    end
    def notification_level=(arg)
      deprecation_warning("notification_level=", "exception_notifiable_notification_level=", @@namespacing)
      exception_notifiable_notification_level = arg
    end

    def deprecation_warning(old, new, reason = "")
      puts "[DEPRECATION WARNING] ** Method '#{old}' has been replaced by '#{new}', please update your code.#{' Reason for change: ' + reason + '.' if reason}"
    end
  end
end
