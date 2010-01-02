require 'ipaddr'

module ExceptionNotifiable
  include SuperExceptionNotifier::NotifiableHelper

  def self.included(base)
    base.extend ClassMethods

    # Adds the following class attributes to the classes that include ExceptionNotifiable
    #  HTTP status codes and what their 'English' status message is
    base.cattr_accessor :http_status_codes
    base.http_status_codes = HTTP_STATUS_CODES
    # error_layout:
    #   can be defined at controller level to the name of the desired error layout,
    #   or set to true to render the controller's own default layout,
    #   or set to false to render errors with no layout
    base.cattr_accessor :error_layout
    base.error_layout = nil
    # Rails error classes to rescue and how to rescue them (which error code to use)
    base.cattr_accessor :error_class_status_codes
    base.error_class_status_codes = self.codes_for_error_classes
    # Verbosity of the gem
    base.cattr_accessor :exception_notifiable_verbose
    base.exception_notifiable_verbose = false
    # Do Not Ever send error notification emails for these Error Classes
    base.cattr_accessor :exception_notifiable_silent_exceptions
    base.exception_notifiable_silent_exceptions = SILENT_EXCEPTIONS
    # Notification Level
    base.cattr_accessor :exception_notifiable_notification_level
    base.exception_notifiable_notification_level = [:render, :email, :web_hooks]
  end
  
  module ClassMethods
    include SuperExceptionNotifier::DeprecatedMethods

    # specifies ip addresses that should be handled as though local
    def consider_local(*args)
      local_addresses.concat(args.flatten.map { |a| IPAddr.new(a) })
    end

    def local_addresses
      addresses = read_inheritable_attribute(:local_addresses)
      unless addresses
        addresses = [IPAddr.new("127.0.0.1")]
        write_inheritable_attribute(:local_addresses, addresses)
      end
      addresses
    end

    # set the exception_data deliverer OR retrieve the exception_data
    def exception_data(deliverer = nil)
      if deliverer
        write_inheritable_attribute(:exception_data, deliverer)
      else
        read_inheritable_attribute(:exception_data)
      end
    end

    def be_silent_for_exception?(exception)
      self.exception_notifiable_silent_exceptions.respond_to?(:any?) && self.exception_notifiable_silent_exceptions.any? {|klass| klass === exception }
    end

  end

  def be_silent_for_exception?(exception)
    self.class.be_silent_for_exception?(exception)
  end


  private

    def notification_level_sends_email?
      self.class.exception_notifiable_notification_level.include?(:email)
    end

    def notification_level_sends_web_hooks?
      self.class.exception_notifiable_notification_level.include?(:web_hooks)
    end

    def notification_level_renders?
      self.class.exception_notifiable_notification_level.include?(:render)
    end

    # overrides Rails' local_request? method to also check any ip
    # addresses specified through consider_local.
    def local_request?
      remote = IPAddr.new(request.remote_ip)
      !self.class.local_addresses.detect { |addr| addr.include?(remote) }.nil?
    end

    # When the action being executed has its own local error handling (rescue)
    # Or when the error accurs somewhere without a subsequent render (eg. method calls in console)
    def rescue_with_handler(exception)
      to_return = super
      if to_return
        verbose = self.class.exception_notifiable_verbose
        puts "[RESCUE STYLE] rescue_with_handler" if verbose
        data = get_exception_data
        status_code = status_code_for_exception(exception)
        #We only send email if it has been configured in environment
        send_email = should_email_on_exception?(exception, status_code, verbose)
        #We only send web hooks if they've been configured in environment
        send_web_hooks = should_web_hook_on_exception?(exception, status_code, verbose)
        the_blamed = ExceptionNotifier.config[:git_repo_path].nil? ? nil : lay_blame(exception)
        rejected_sections = %w(request session)
        # Debugging output
        verbose_output(exception, status_code, "rescued by handler", send_email, send_web_hooks, nil, the_blamed, rejected_sections) if verbose
        # Send the exception notification email
        perform_exception_notify_mailing(exception, data, nil, the_blamed, verbose, rejected_sections) if send_email
        # Send Web Hook requests
        HooksNotifier.deliver_exception_to_web_hooks(ExceptionNotifier.config, exception, self, request, data, the_blamed) if send_web_hooks
      end
      to_return
    end

    # When the action being executed is letting SEN handle the exception completely
    def rescue_action_in_public(exception)
      # If the error class is NOT listed in the rails_errror_class hash then we get a generic 500 error:
      # OTW if the error class is listed, but has a blank code or the code is == '200' then we get a custom error layout rendered
      # OTW the error class is listed!
      verbose = self.class.exception_notifiable_verbose
      puts "[RESCUE STYLE] rescue_action_in_public" if verbose
      status_code = status_code_for_exception(exception)
      if status_code == '200'
        notify_and_render_error_template(status_code, request, exception, ExceptionNotifier.get_view_path_for_class(exception, verbose), verbose)
      else
        notify_and_render_error_template(status_code, request, exception, ExceptionNotifier.get_view_path_for_status_code(status_code, verbose), verbose)
      end
    end

    def notify_and_render_error_template(status_cd, request, exception, file_path, verbose = false)
      status = self.class.http_status_codes[status_cd] ? status_cd + " " + self.class.http_status_codes[status_cd] : status_cd
      data = get_exception_data
      #We only send email if it has been configured in environment
      send_email = should_email_on_exception?(exception, status_cd, verbose)
      #We only send web hooks if they've been configured in environment
      send_web_hooks = should_web_hook_on_exception?(exception, status_cd, verbose)
      the_blamed = ExceptionNotifier.config[:git_repo_path].nil? ? nil : lay_blame(exception)
      rejected_sections = request.nil? ? %w(request session) : []
      # Debugging output
      verbose_output(exception, status_cd, file_path, send_email, send_web_hooks, request, the_blamed, rejected_sections) if verbose
      #TODO: is _rescue_action something from rails 3?
      #if !(self.controller_name == 'application' && self.action_name == '_rescue_action')
      # Send the exception notification email
      perform_exception_notify_mailing(exception, data, request, the_blamed, verbose, rejected_sections) if send_email
      # Send Web Hook requests
      HooksNotifier.deliver_exception_to_web_hooks(ExceptionNotifier.config, exception, self, request, data, the_blamed) if send_web_hooks

      # We put the render call after the deliver call to ensure that, if the
      # deliver raises an exception, we don't call render twice.
      # Render the error page to the end user
      render_error_template(file_path, status)
    end

    def is_local?
      (consider_all_requests_local || local_request?)
    end

    def status_code_for_exception(exception)
      self.class.error_class_status_codes[exception.class].nil? ? 
              '500' :
              self.class.error_class_status_codes[exception.class].blank? ?
                      '200' :
                      self.class.error_class_status_codes[exception.class]
    end

    def render_error_template(file, status)
      respond_to do |type|
        type.html { render :file => file,
                            :layout => self.class.error_layout,
                            :status => status }
        type.all  { render :nothing => true,
                            :status => status}
      end
    end

end
