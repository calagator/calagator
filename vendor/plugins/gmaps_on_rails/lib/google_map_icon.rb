class GoogleMapIcon
  # CALAGATOR: added "rescue nil" to tolerate missing Reloadable
  include Reloadable rescue nil
  include UnbackedDomId
  
  attr_accessor :width,
                :height,
                :shadow_width,
                :shadow_height,
                :image_url,
                :shadow_url,
                :anchor_x,
                :anchor_y,
                :info_anchor_x,
                :info_anchor_y
  
  def initialize(options = {})
    self.image_url       = 'http://www.google.com/mapfiles/marker.png'
    self.shadow_url      = 'http://www.google.com/mapfiles/shadow50.png'
    self.width           = 20
    self.height          = 34
    self.shadow_width    = 37
    self.shadow_height   = 34
    self.anchor_x        = 6
    self.anchor_y        = 20
    self.info_anchor_x   = 5
    self.info_anchor_y   = 1
    
    options.each_pair { |key, value| send("#{key}=", value) }
  end
  
  def to_js
    js = []
    
    js << "var #{dom_id} = new GIcon();"
    js << "#{dom_id}.image = \"#{image_url}\";"
    js << "#{dom_id}.shadow = \"#{shadow_url}\";"
    js << "#{dom_id}.iconSize = new GSize(#{width}, #{height});"
    js << "#{dom_id}.shadowSize = new GSize(#{shadow_width}, #{shadow_height});"
    js << "#{dom_id}.iconAnchor = new GPoint(#{anchor_x}, #{anchor_y});"
    js << "#{dom_id}.infoWindowAnchor = new GPoint(#{info_anchor_x}, #{info_anchor_y});"
    
    return js.join("\n")
  end
  
  def to_html
    html = []
    
    html << "<script type=\"text/javascript\">\n/* <![CDATA[ */\n"  
    html << to_js
    html << "/* ]]> */</script> "
    
    return html.join("\n")
  end
end