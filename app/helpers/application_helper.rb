# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  FLASH_TYPES = [:success, :failure]

  def render_flash
    result = ""
    for name in FLASH_TYPES
      result += "<div class='flash_#{name}'>#{flash[name]}</div>" if flash[name]
      flash[name] = nil
    end
    return(result.blank? ? nil : "<div id='flash'>#{result}</div>")
  end

  def datetime_format(time,format)
    format = format.gsub(/(%[dHImU])/,'*\1')
    time.strftime(format).gsub(/\*0*/,'')
  end
  
  def google_map(locatable_items, options={})
    # Adapt the gmaps_on_rails plugin to talk to our locatable items.
    # Return markup containing a Google map with markers for these items, or
    # nil if no items have locations.
    # - "locatable_items" can be one item or an array of them.
    # - A locatable item is anything that responds_to? :location and 
    #   :title (yes, our Events and Venues both qualify).
    # - A locatable item with a nil location will be ignored
    
    # The plugin uses Google Maps automatic zooming to set the scale, but 
    # the little overview map obscures such a big chunk of the main map that
    # it's likely to hide some of our markers, so it's off by default.
    options[:controls] = [:zoom, :scale, :type] # the default, minus :overview

    # Make the map and our marker(s)
    map = GoogleMap.new(options)
    [locatable_items].flatten.each do |locatable_item|
      location = locatable_item.location
      if location
        map.markers << GoogleMapMarker.new(:map => map, 
          :lat => location[0], :lng => location[1],
          :html => h(locatable_item.title))
      end
    end
    map.to_html + map.div(nil) unless map.markers.empty?
  end

  # Retrun a string describing the source code version being used, or false/nil if it can't figure out how to find the version.
  def source_code_version
    if File.directory?(File.join(RAILS_ROOT, ".svn"))
      $svn_revision ||= \
        if m = `svn info`.match(/^Revision: (\d+)/s)
          "SVN Version: #{m[1]}"
        end
    elsif File.directory?(File.join(RAILS_ROOT, ".git"))
      $git_date ||= \
        if m = `git log -1`.match(/^Date: (.+?)$/s)
          "Git Timestamp: #{m[1]}"
        end
    end
  end
end
