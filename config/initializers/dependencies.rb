#===[ Standard Libraries ]==============================================

require 'fileutils'
require 'net/http'
require 'net/https'
require 'open-uri'
require 'set'
require 'uri'
require 'uri'

#===[ /lib ]============================================================

require 'rexml-expansion-fix' # TODO Remove this after switching to a patched Ruby or Rails version
require 'metaclass'
require 'tagging_extensions'
require 'ext'

#===[ /vendor/gems ]====================================================

$LOAD_PATH << Dir["#{RAILS_ROOT}/vendor/gems/facets-*/lib"].first
require 'facets/boolean' # true? false?
require 'facets/kernel/d' # Like 'p' but displays line number
require 'facets/kernel/ergo' # Executes method only on non-nils
require 'facets/kernel/in' # Does self contain one of the arguments?
require 'facets/kernel/instance_exec' # Like instance_eval but can pass arguments
require 'facets/kernel/not_nil' # Provides #not_nil?
require 'facets/kernel/populate' # Assign multiple values to object via #populate and #set_from
require 'facets/kernel/try' # Executes method only if object responds to it
require 'facets/kernel/val' # Object has a value?
require 'facets/kernel/with' # Like #returning but using #instance_eval.
