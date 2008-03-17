#===[ Local libraries ]=================================================

require 'metaclass'

#===[ Vendor gems ]=====================================================

def add_gem_to_load_path(*names)
  for name in names
    $LOAD_PATH.unshift(File.expand_path(File.join(RAILS_ROOT, "vendor", "gems", name, "lib")))
  end
end

add_gem_to_load_path 'htmlentities-4.0.0'
add_gem_to_load_path 'vpim-0.360'
