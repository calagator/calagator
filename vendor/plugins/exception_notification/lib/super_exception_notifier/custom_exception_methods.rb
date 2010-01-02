#Copyright (c) 2008-2009 Peter H. Boling of 9thBit LLC
#Released under the MIT license

module SuperExceptionNotifier
  module CustomExceptionMethods

    protected
    
    #For a while after disabling a route/URL that had been functional we should set it to resource gone to inform people to remove bookmarks.
    def resource_gone
      raise ResourceGone
    end
    #Then for things that have never existed or have not for a long time we call not_implemented
    def not_implemented
      raise NotImplemented
    end
    #Resources that must be requested with a specific HTTP Method (GET, PUT, POST, DELETE, AJAX, etc) but are requested otherwise should:
    def invalid_method
      raise InvalidMethod
    end
    #If your ever at a spot in the code that should never get reached, but corrupt data might get you there anyways then this is for you:
    def corrupt_data
      raise CorruptData
    end
    def page_not_found
      raise PageNotFound
    end
    def record_not_found
      raise ActiveRecord::RecordNotFound
    end
    def method_disabled
      raise MethodDisabled
    end
    #The current user does not have enough privileges to access the requested resource
    def access_denied
      raise AccessDenied
    end

    def generic_error
      error_stickie("Sorry, an error has occurred.")
      corrupt_data
    end

    def invalid_page
      error_stickie("Sorry, the page number you requested was not valid.")
      page_not_found
    end

  end
end
