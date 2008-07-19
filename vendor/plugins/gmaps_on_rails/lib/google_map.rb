class GoogleMap
  # CALAGATOR: added "rescue nil" to tolerate missing Reloadable
  include Reloadable rescue nil
  include UnbackedDomId
  attr_accessor :dom_id,
                :markers,
                :controls,
                :center, # CALAGATOR: added.
                :inject_on_load,
                :zoom
  
  def initialize(options = {})
    self.dom_id = 'google_map'
    self.markers = []
    self.controls = [ :zoom, :overview, :scale, :type ]
    options.each_pair { |key, value| send("#{key}=", value) }
  end
  
  def to_html
    html = []
    
    html << "<script src='http://maps.google.com/maps?file=api&amp;v=2&amp;key=#{GOOGLE_APPLICATION_ID}' type='text/javascript'></script>"
    
    html << "<script type=\"text/javascript\">\n/* <![CDATA[ */\n"  
    html << to_js
    html << "/* ]]> */</script> "
    
    return html.join("\n")
  end

  def to_js
    js = []
    
    # Initialise the map variable so that it can externally accessed.
    js << "var #{dom_id};"
    markers.each { |marker| js << "var #{marker.dom_id};" }
    
    js << markers_functions_js
    
    js << center_on_markers_function_js
    
    js << "function initialize_google_map_#{dom_id}() {"
    js << "  if(GBrowserIsCompatible()) {"
    js << "    #{dom_id} = new GMap2(document.getElementById('#{dom_id}'));"
    
    js << '    ' + controls_js
    
    js << '    ' + center_on_markers_js
    
    js << '    ' + markers_icons_js
    
    # Put all the markers on the map.
    for marker in markers
      js << '    ' + marker.to_js
      js << ''
    end
    
    js << '    ' + inject_on_load.gsub("\n", "    \n") if inject_on_load
    
    js << "  }"
    js << "}"
    
    # Load the map on window load preserving anything already on window.onload.

# CALAGATOR: jQuery will make the load happen after page layout:
    js << "$(window).load(initialize_google_map_#{dom_id});"

# CALAGATOR: ... where this code blocked layout, which makes things look slow.
#    js << "if (typeof window.onload != 'function') {"
#    js << "  window.onload = initialize_google_map_#{dom_id};"
#    js << "} else {"
#    js << "  old_before_google_map_#{dom_id} = window.onload;"
#    js << "  window.onload = function() {" 
#    js << "    old_before_google_map_#{dom_id}();"
#    js << "    initialize_google_map_#{dom_id}();" 
#    js << "  }"
#    js << "}"
    # Unload the map on window load preserving anything already on window.onunload.
    #js << "if (typeof window.onunload != 'function') {"
    #js << "  window.onunload = GUnload();"
    #js << "} else {"
    #js << "  old_before_onunload = window.onload;"
    #js << "  window.onunload = function() {" 
    #js << "    old_before_onunload;"
    #js << "    GUnload();" 
    #js << "  }"
    #js << "}"
        
    return js.join("\n")
  end
  
  def controls_js
    js = []
    
    controls.each do |control|
      case control
        when :large, :small, :overview
          c = "G#{control.to_s.capitalize}MapControl"
        when :scale
          c = "GScaleControl"
        when :type
          c = "GMapTypeControl"
        when :zoom
          c = "GSmallZoomControl"
      end
      js << "#{dom_id}.addControl(new #{c}());"
    end
    
    return js.join("\n")
  end
  
  def markers_functions_js
    js = []
    
    for marker in markers
      js << marker.open_info_window_function
    end
    
    return js.join("\n")
  end
  
  def markers_icons_js
    icons = []
    
    for marker in markers
      if marker.icon and !icons.include?(marker.icon)
        icons << marker.icon 
      end
    end
    
    js = []
    
    for icon in icons
      js << icon.to_js
    end
    
    return js.join("\n")
  end
  
  # Creates a JS function that centers the map on its markers.
  def center_on_markers_function_js
    # CALAGATOR: Added support for external :center option
    unless self.zoom and self.center
      return "#{dom_id}.setCenter(new GLatLng(0, 0), 0);" if markers.size == 0
      
      for marker in markers
        min_lat = marker.lat if !min_lat or marker.lat < min_lat
        max_lat = marker.lat if !max_lat or marker.lat > max_lat
        min_lng = marker.lng if !min_lng or marker.lng < min_lng
        max_lng = marker.lng if !max_lng or marker.lng > max_lng
      end
    end

    if self.zoom
      zoom_js = zoom
    else
      bounds_js = "new GLatLngBounds(new GLatLng(#{min_lat}, #{min_lng}), new GLatLng(#{max_lat}, #{max_lng}))"
      zoom_js = "#{dom_id}.getBoundsZoomLevel(#{bounds_js})"
    end
    
    # CALAGATOR: More :center support
    if self.center
      center_js = "new GLatLng(#{self.center[0]}, #{self.center[1]})"
    else
      center_js = "new GLatLng(#{(min_lat + max_lat) / 2}, #{(min_lng + max_lng) / 2})"
    end
    set_center_js = "#{dom_id}.setCenter(#{center_js}, #{zoom_js});"
    
    return "function center_#{dom_id}() {\n  #{check_resize_js}\n  #{set_center_js}\n}"
  end
  
  def check_resize_js
    return "#{dom_id}.checkResize();"
  end
  
  def center_on_markers_js
    return "center_#{dom_id}();"
  end
  
  def div(width = '100%', height = '100%')
    # CALAGATOR: we keep style in CSS, so allow the style to be suppressed
    # was: "<div id='#{dom_id}' style='width: #{width}; height: #{height}'></div>"
    if width.nil?
      "<div id='#{dom_id}'></div>"
    else
      "<div id='#{dom_id}' style='width: #{width}; height: #{height}'></div>"
    end
  end
end
