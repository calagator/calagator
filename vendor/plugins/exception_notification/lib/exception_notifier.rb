require 'pathname'

class ExceptionNotifier < ActionMailer::Base

  #andrewroth reported that @@config gets clobbered because rails loads this class twice when installed as a plugin, and adding the ||= fixed it.
  @@config ||= {
    # If left empty web hooks will not be engaged
    :web_hooks                => [],
    :app_name                 => "[MYAPP]",
    :version                  => "0.0.0",
    :sender_address           => "super.exception.notifier@example.com",
    :exception_recipients     => [],
    # Customize the subject line
    :subject_prepend          => "[#{(defined?(Rails) ? Rails.env : RAILS_ENV).capitalize} ERROR] ",
    :subject_append           => nil,
    # Include which sections of the exception email? 
    :sections                 => %w(request session environment backtrace),
    :skip_local_notification  => true,
    :view_path                => nil,
    #Error Notification will be sent if the HTTP response code for the error matches one of the following error codes
    :notify_error_codes   => %W( 405 500 503 ),
    #Error Notification will be sent if the error class matches one of the following error error classes
    :notify_error_classes => %W( ),
    :notify_other_errors  => true,
    :git_repo_path            => nil,
    :template_root            => "#{File.dirname(__FILE__)}/../views"
  }

  cattr_accessor :config

  def self.configure_exception_notifier(&block)
    yield @@config
  end
  
  self.template_root = config[:template_root]

  def self.reloadable?() false end

  # Returns an array of potential filenames to look for
  # eg. For the Exception Class - SuperExceptionNotifier::CustomExceptionClasses::MethodDisabled
  # the filename handles are:
  #   super_exception_notifier_custom_exception_classes_method_disabled
  #   method_disabled
  def self.exception_to_filenames(exception)
    filenames = []
    e = exception.to_s
    filenames << ExceptionNotifier.filenamify(e)

    last_colon = e.rindex(':')
    unless last_colon.nil?
      filenames << ExceptionNotifier.filenamify(e[(last_colon + 1)..(e.length - 1)])
    end
    filenames
  end

  def self.sections_for_email(rejected_sections, request)
    rejected_sections = rejected_sections.nil? ? request.nil? ? %w(request session) : [] : rejected_sections
    rejected_sections.empty? ? config[:sections] : config[:sections].reject{|s| rejected_sections.include?(s) }
  end

  # Converts Stringified Class Names to acceptable filename handles with underscores
  def self.filenamify(str)
    str.delete(':').gsub( /([A-Za-z])([A-Z])/, '\1' << '_' << '\2').downcase
  end

  # What is the path of the file we will render to the user based on a given status code?
  def self.get_view_path_for_status_code(status_cd, verbose = false)
    file_name = ExceptionNotifier.get_view_path(status_cd, verbose)
    #ExceptionNotifierHelper::COMPAT_MODE ? "#{File.dirname(__FILE__)}/../rails/app/views/exception_notifiable/500.html" : "500.html"
    file_name.nil? ? self.catch_all(verbose) : file_name
  end

#  def self.get_view_path_for_files(filenames = [])
#    filepaths = filenames.map do |file|
#      ExceptionNotifier.get_view_path(file)
#    end.compact
#    filepaths.empty? ? "#{File.dirname(__FILE__)}/../rails/app/views/exception_notifiable/500.html" : filepaths.first
#  end

  # What is the path of the file we will render to the user based on a given exception class?
  def self.get_view_path_for_class(exception, verbose = false)
    return self.catch_all(verbose) if exception.nil?
    #return self.catch_all(verbose) unless exception.is_a?(StandardError) || exception.is_a?(Class) # For some reason exception.is_a?(Class) works in console, but not when running in mongrel (ALWAYS returns false)?!?!?
    filepaths = ExceptionNotifier.exception_to_filenames(exception).map do |file|
      ExceptionNotifier.get_view_path(file, verbose)
    end.compact
    filepaths.empty? ? self.catch_all(verbose) : filepaths.first
  end

  def self.catch_all(verbose = false)
    puts "[CATCH ALL INVOKED] #{File.dirname(__FILE__)}/../rails/app/views/exception_notifiable/500.html" if verbose
    "#{File.dirname(__FILE__)}/../rails/app/views/exception_notifiable/500.html"
  end

  # Check the usual suspects
  def self.get_view_path(file_name, verbose = false)
    if File.exist?("#{RAILS_ROOT}/public/#{file_name}.html")
      puts "[FOUND FILE:A] #{RAILS_ROOT}/public/#{file_name}.html" if verbose
      "#{RAILS_ROOT}/public/#{file_name}.html"
    elsif !config[:view_path].nil? && File.exist?("#{RAILS_ROOT}/#{config[:view_path]}/#{file_name}.html.erb")
      puts "[FOUND FILE:B] #{RAILS_ROOT}/#{config[:view_path]}/#{file_name}.html.erb" if verbose
      "#{RAILS_ROOT}/#{config[:view_path]}/#{file_name}.html.erb"
    elsif !config[:view_path].nil? && File.exist?("#{RAILS_ROOT}/#{config[:view_path]}/#{file_name}.html")
      puts "[FOUND FILE:C] #{RAILS_ROOT}/#{config[:view_path]}/#{file_name}.html" if verbose
      "#{RAILS_ROOT}/#{config[:view_path]}/#{file_name}.html"
    elsif File.exist?("#{File.dirname(__FILE__)}/../rails/app/views/exception_notifiable/#{file_name}.html.erb")
      puts "[FOUND FILE:D] #{File.dirname(__FILE__)}/../rails/app/views/exception_notifiable/#{file_name}.html.erb" if verbose
      "#{File.dirname(__FILE__)}/../rails/app/views/exception_notifiable/#{file_name}.html.erb"
    elsif File.exist?("#{File.dirname(__FILE__)}/../rails/app/views/exception_notifiable/#{file_name}.html")
      #ExceptionNotifierHelper::COMPAT_MODE ? "#{File.dirname(__FILE__)}/../rails/app/views/exception_notifiable/#{file_name}.html" : "#{status_cd}.html"
      puts "[FOUND FILE:E] #{File.dirname(__FILE__)}/../rails/app/views/exception_notifiable/#{file_name}.html" if verbose
      "#{File.dirname(__FILE__)}/../rails/app/views/exception_notifiable/#{file_name}.html"
    else
      nil
    end
  end

  def exception_notification(exception, class_name = nil, method_name = nil, request = nil, data = {}, the_blamed = nil, rejected_sections = nil)
    body_hash = error_environment_data_hash(exception, class_name, method_name, request, data, the_blamed, rejected_sections)
    #Prefer to have custom, potentially HTML email templates available
    #content_type  "text/plain"
    recipients    config[:exception_recipients]
    from          config[:sender_address]

    request.session.inspect unless request.nil? # Ensure session data is loaded (Rails 2.3 lazy-loading)
    
    subject       "#{config[:subject_prepend]}#{body_hash[:location]} (#{exception.class}) #{exception.message.inspect}#{config[:subject_append]}"
    body          body_hash
  end
  
  def background_exception_notification(exception, data = {}, the_blamed = nil, rejected_sections = %w(request session))
    exception_notification(exception, nil, nil, nil, data, the_blamed, rejected_sections)
  end

  def rake_exception_notification(exception, task, data={}, the_blamed = nil, rejected_sections = %w(request session))
    exception_notification(exception, "", "#{task.name}", nil, data, the_blamed, rejected_sections)
  end

  private

    def error_environment_data_hash(exception, class_name = nil, method_name = nil, request = nil, data = {}, the_blamed = nil, rejected_sections = nil)
      data.merge!({
        :exception => exception,
        :backtrace => sanitize_backtrace(exception.backtrace),
        :rails_root => rails_root,
        :data => data,
        :the_blamed => the_blamed
      })

      data.merge!({:class_name => class_name}) if class_name
      data.merge!({:method_name => method_name}) if method_name
      if class_name && method_name
        data.merge!({:location => "#{class_name}##{method_name}"})
      elsif method_name
        data.merge!({:location => "#{method_name}"})
      else
        data.merge!({:location => sanitize_backtrace([exception.backtrace.first]).first})
      end
      if request
        data.merge!({:request => request})
        data.merge!({:host => (request.env['HTTP_X_REAL_IP'] || request.env["HTTP_X_FORWARDED_HOST"] || request.env["HTTP_HOST"])})
      end
      data.merge!({:sections => ExceptionNotifier.sections_for_email(rejected_sections, request)})
      return data
    end

    def sanitize_backtrace(trace)
      re = Regexp.new(/^#{Regexp.escape(rails_root)}/)
      trace.map { |line| Pathname.new(line.gsub(re, "[RAILS_ROOT]")).cleanpath.to_s }
    end

    def rails_root
      @rails_root ||= Pathname.new(RAILS_ROOT).cleanpath.to_s
    end

end
