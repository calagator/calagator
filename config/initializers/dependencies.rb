#===[ Standard Libraries ]==============================================

require 'fileutils'
require 'net/http'
require 'net/https'
require 'open-uri'
require 'set'
require 'uri'

#===[ /lib ]============================================================

require 'metaclass'
require 'tagging_extensions'
require 'ext'
require 'defer_proxy'

#===[ /vendor/plugins ]=================================================

# The `has_many_polymorphs` 2.13 gem is horribly broken, obsolete and incompatible. A hacked version called 2.13.4 provides Rails 2.3 support and is available at https://github.com/johnsbrn/has_many_polymorphs . This bundled version uses the same code, but simply fixes the deprecation warnings caused by the `returning` calls.
require 'vendor/plugins/has_many_polymorphs/lib/has_many_polymorphs'

#===[ fin ]=============================================================
