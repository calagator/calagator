module Notifiable
  include SuperExceptionNotifier::NotifiableHelper
  
  def self.included(base)
    base.extend ClassMethods

    # Verbosity of the gem
    base.cattr_accessor :notifiable_verbose
    base.notifiable_verbose = false
    # Do Not Ever send error notification emails for these Error Classes
    base.cattr_accessor :notifiable_silent_exceptions
    base.notifiable_silent_exceptions = SILENT_EXCEPTIONS
    # Notification Level
    base.cattr_accessor :notifiable_notification_level
    base.notifiable_notification_level = [:email, :web_hooks]

    # Since there is no concept of locality from a request here allow user to explicitly define which env's are noisy (send notifications)
    base.cattr_accessor :notifiable_noisy_environments
    base.notifiable_noisy_environments = [:production]
  end

  module ClassMethods
    # set the exception_data deliverer OR retrieve the exception_data
    def exception_data(deliverer = nil)
      if deliverer
        write_inheritable_attribute(:exception_data, deliverer)
      else
        read_inheritable_attribute(:exception_data)
      end
    end

    def be_silent_for_exception?(exception)
      self.notifiable_silent_exceptions.respond_to?(:any?) && self.notifiable_silent_exceptions.any? {|klass| klass === exception }
    end

  end

  # Usage:
  #   notifiable { Klass.some_method }
  # This will rescue any errors that occur within Klass.some_method
  def notifiable(&block)
    yield
  rescue => exception
    rescue_with_hooks(exception)
    raise
  end

  def be_silent_for_exception?(exception)
    self.class.be_silent_for_exception?(exception)
  end

  private

  def notification_level_sends_email?
    self.class.notifiable_notification_level.include?(:email)
  end

  def notification_level_sends_web_hooks?
    self.class.notifiable_notification_level.include?(:web_hooks)
  end
  
  def rescue_with_hooks(exception)
    verbose = self.class.notifiable_verbose
    puts "[RESCUE STYLE] rescue_with_hooks" if verbose
    data = get_exception_data
    # With ExceptionNotifiable you have an inherent request, and using a status code makes sense.
    # With Notifiable class to wrap around everything that doesn't have a request,
    #   the errors you want to be notified of need to be specified either positively or negatively
    # 1. positive eg. set ExceptionNotifier.config[:notify_error_classes] to an array of classes
    #               set ExceptionNotifier.config[:notify_other_errors] to false
    # 1. negative eg. set Klass.silent_exceptions to the ones to keep quiet
    #               set ExceptionNotifier.config[:notify_other_errors] to true
    status_code = nil
    #We only send email if it has been configured in environment
    send_email = should_email_on_exception?(exception, status_code, verbose)
    #We only send web hooks if they've been configured in environment
    send_web_hooks = should_web_hook_on_exception?(exception, status_code, verbose)
    the_blamed = ExceptionNotifier.config[:git_repo_path].nil? ? nil : lay_blame(exception)
    rejected_sections = %w(request session)
    verbose_output(exception, status_code, "rescued by handler", send_email, send_web_hooks, nil, the_blamed, rejected_sections) if verbose
    # Send the exception notification email
    perform_exception_notify_mailing(exception, data, nil, the_blamed, verbose, rejected_sections) if send_email
    # Send Web Hook requests
    HooksNotifier.deliver_exception_to_web_hooks(ExceptionNotifier.config, exception, self, request, data, the_blamed) if send_web_hooks
  end

  def is_local? #like asking is_silent?
    eenv = defined?(Rails) ? Rails.env : RAILS_ENV
    !self.notifiable_noisy_environments.include?(eenv)
  end

end
