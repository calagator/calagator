#===[ Standard Libraries ]==============================================

require 'open-uri'
require 'set'
require 'uri'

#===[ /lib ]============================================================

require 'metaclass'

#===[ /vendor/gems ]====================================================

def add_vendor_gem_to_load_path(*names)
  names.each{|name| $LOAD_PATH.unshift("#{RAILS_ROOT}/vendor/gems/#{name}/lib")}
end

add_vendor_gem_to_load_path 'htmlentities-4.0.0'
require 'htmlentities'

add_vendor_gem_to_load_path 'vpim-0.360'
require 'vpim/icalendar'
require 'vpim/vcard'

add_vendor_gem_to_load_path 'tzinfo-0.3.8'
require 'tzinfo'
