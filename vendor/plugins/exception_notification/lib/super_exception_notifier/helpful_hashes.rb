#Copyright (c) 2008-2009 Peter H. Boling of 9thBit LLC
#Released under the MIT license

module SuperExceptionNotifier
  module HelpfulHashes
    unless defined?(SILENT_EXCEPTIONS)
      noiseless = []
      noiseless << ActiveRecord::RecordNotFound if defined?(ActiveRecord)
      if defined?(ActionController)
        noiseless << ActionController::UnknownController
        noiseless << ActionController::UnknownAction
        noiseless << ActionController::RoutingError
        noiseless << ActionController::MethodNotAllowed
      end
      SILENT_EXCEPTIONS = noiseless
    end

    # TODO: use ActionController::StatusCodes
    HTTP_STATUS_CODES = {
      "400" => "Bad Request",
      "403" => "Forbidden",
      "404" => "Not Found",
      "405" => "Method Not Allowed",
      "410" => "Gone",
      "418" => "I'm a teapot",
      "422" => "Unprocessable Entity",
      "423" => "Locked",
      "500" => "Internal Server Error",
      "501" => "Not Implemented",
      "503" => "Service Unavailable"
    } unless defined?(HTTP_STATUS_CODES)

    def codes_for_error_classes
      #TODO: Format whitespace
      classes = {
        # These are standard errors in rails / ruby
        NameError => "503",
        TypeError => "503",
        RuntimeError => "500",
        ArgumentError => "500",
        # These are custom error names defined in lib/super_exception_notifier/custom_exception_classes
        AccessDenied => "403",
        PageNotFound => "404",
        InvalidMethod => "405",
        ResourceGone => "410",
        CorruptData => "422",
        NoMethodError => "500",
        NotImplemented => "501",
        MethodDisabled => "200"
      }
      # Highly dependent on the verison of rails, so we're very protective about these'
      classes.merge!({ ActionView::TemplateError => "500"})             if defined?(ActionView)       && ActionView.const_defined?(:TemplateError)
      classes.merge!({ ActiveRecord::RecordNotFound => "400" })         if defined?(ActiveRecord)     && ActiveRecord.const_defined?(:RecordNotFound)
      classes.merge!({ ActiveResource::ResourceNotFound => "404" })     if defined?(ActiveResource)   && ActiveResource.const_defined?(:ResourceNotFound)

      if defined?(ActionController)
        classes.merge!({ ActionController::UnknownController => "404" })          if ActionController.const_defined?(:UnknownController)
        classes.merge!({ ActionController::MissingTemplate => "404" })            if ActionController.const_defined?(:MissingTemplate)
        classes.merge!({ ActionController::MethodNotAllowed => "405" })           if ActionController.const_defined?(:MethodNotAllowed)
        classes.merge!({ ActionController::UnknownAction => "501" })              if ActionController.const_defined?(:UnknownAction)
        classes.merge!({ ActionController::RoutingError => "404" })               if ActionController.const_defined?(:RoutingError)
        classes.merge!({ ActionController::InvalidAuthenticityToken => "405" })   if ActionController.const_defined?(:InvalidAuthenticityToken)
      end
    end
  end
end
