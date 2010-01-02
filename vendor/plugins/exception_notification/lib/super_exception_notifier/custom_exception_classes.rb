#Copyright (c) 2008-2009 Peter H. Boling of 9thBit LLC
#Released under the MIT license

module SuperExceptionNotifier
  module CustomExceptionClasses

    class AccessDenied < StandardError; end
    class ResourceGone < StandardError; end
    class NotImplemented < StandardError; end
    class PageNotFound < StandardError; end
    class InvalidMethod < StandardError; end
    class CorruptData < StandardError; end
    class MethodDisabled < StandardError; end
    
  end
end
