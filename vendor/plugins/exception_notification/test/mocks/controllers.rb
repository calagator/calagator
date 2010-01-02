module Rails
  def self.public_path
    File.dirname(__FILE__)
  end

  def self.env
    'test'
  end
end

class Application < ActionController::Base

  def runtime_error
    raise "This is a runtime error that we should be emailed about"
  end

  def ar_record_not_found
    #From SuperExceptionNotifier::CustomExceptionMethods
    record_not_found
  end

  def name_error
    raise NameError
  end

  def unknown_controller
    raise ActionController::UnknownController
  end

  def local_request?
    false
  end
  
end

class SpecialErrorThing < RuntimeError
end

class BasicController < Application
  include ExceptionNotifiable
end

class CustomSilentExceptions < Application
  include ExceptionNotifiable
  self.exception_notifiable_verbose = false
  self.exception_notifiable_silent_exceptions = [RuntimeError]
end

class EmptySilentExceptions < Application
  include ExceptionNotifiable
  self.exception_notifiable_verbose = false
  self.exception_notifiable_silent_exceptions = []
end

class NilSilentExceptions < Application
  include ExceptionNotifiable
  self.exception_notifiable_verbose = false
  self.exception_notifiable_silent_exceptions = nil
end

class DefaultSilentExceptions < Application
  include ExceptionNotifiable
  self.exception_notifiable_verbose = false
end

class OldStyle < Application
  include ExceptionNotifiable
  self.exception_notifiable_verbose = false
end

class NewStyle < Application
  include ExceptionNotifiable
  self.exception_notifiable_verbose = false
    
  rescue_from ActiveRecord::RecordNotFound do |exception|
    render :text => "404", :status => 404
  end

  rescue_from RuntimeError do |exception|
    render :text => "500", :status => 500
  end
end
