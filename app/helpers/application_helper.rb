# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  # Returns HTML string of an event or venue description for display in a view.
  def format_description(string)
    return upgrade_br(simple_format(auto_link(white_list(string.gsub(%r{<br\s?/?>}, "\n")))))
  end

  # Return a HTML string with the BR tags converted to XHTML compliant markup.
  def upgrade_br(content)
    content.gsub('<br>','<br />')
  end

  FLASH_TYPES = [:success, :failure]

  def render_flash
    result = ""
    for name in FLASH_TYPES
      result += "<div class='flash #{name} flash_#{name}'>#{name == :failure ? 'ERROR: ' : ''}#{flash[name]}</div>" if flash[name]
    end
    return(result.blank? ? nil : "<div id='flash'>#{result}</div>")
  end

  def datetime_format(time,format)
    format = format.gsub(/(%[dHImU])/,'*\1')
    time.strftime(format).gsub(/\*0*/,'')
  end

  # Returns HTML for a Google map containing the +locatable_items+.
  #
  # Adapt the gmaps_on_rails plugin to talk to our locatable items.
  # Return markup containing a Google map with markers for these items, or
  # nil if no items have locations.
  # - "locatable_items" can be one item or an array of them.
  # - A locatable item is anything that responds_to? :location and
  #   :title (yes, our Events and Venues both qualify).
  # - A locatable item with a nil location will be ignored
  #
  # The plugin uses Google Maps automatic zooming to set the scale, but
  # the little overview map obscures such a big chunk of the main map that
  # it's likely to hide some of our markers, so it's off by default.
  def google_map(locatable_items, options={})
    return nil if defined?(GoogleMap::GOOGLE_APPLICATION_ID) == nil
    options[:controls] ||= [:zoom, :scale, :type] # the default, minus :overview
    options[:zoom] ||= 14

    # Make the map and our marker(s)
    map = GoogleMap.new(options)
    icon = GoogleMapSmallIcon.new('green')
    [locatable_items].flatten.each do |locatable_item|
      location = locatable_item.location
      if location
        map.markers << GoogleMapMarker.new(:map => map,
          :lat => location[0], :lng => location[1],
          :html => link_to(locatable_item.title, locatable_item),
          :icon => icon)
      end
    end
    map.to_html + map.div(nil) unless map.markers.empty?
  end

  # Retrun a string describing the source code version being used, or false/nil if it can't figure out how to find the version.
  def self.source_code_version_raw
    begin
      if File.directory?(File.join(RAILS_ROOT, ".svn"))
        $svn_revision ||= \
          if s = `svn info 2>&1`
            if m = s.match(/^Revision: (\d+)/s)
              " - SVN revision: #{m[1]}"
            end
          end
      elsif File.directory?(File.join(RAILS_ROOT, ".git"))
        $git_date ||= \
          if s = `git log -1 2>&1`
            if m = s.match(/^Date: (.+?)$/s)
              " - Git timestamp: #{m[1]}"
            end
          end
      elsif File.directory?(File.join(RAILS_ROOT, ".hg"))
        $git_date ||= \
          if s = `hg id -nibt 2>&1`
            " - Mercurial revision: #{s}"
        end
      end
    rescue Errno::ENOENT
      # Platform (e.g., Windows) has the checkout directory but not the command-line command to manipulate it.
      ""
    end
  end

  ApplicationController::SOURCE_CODE_VERSION = self.source_code_version_raw

  def source_code_version
    return ApplicationController::SOURCE_CODE_VERSION
  end

  # returns html markup with source (if any), imported/created time, and - if modified - modified time
  def datestamp(item)
    stamp = "This item was "
    if item.source.nil?
      stamp << "added directly to #{SETTINGS.name}"
    else
      stamp << "imported from " << link_to(truncate(item.source.name, :length => 40), item.source)
    end
    stamp << " <br />" << content_tag(:strong, normalize_time(item.created_at, :format => :html) )
    if item.updated_at > item.created_at
      stamp << " and last updated <br />" << content_tag(:strong, normalize_time(item.updated_at, :format => :html) )
    end
    stamp << "."
  end

  # Caches +block+ in view only if the +condition+ is true.
  # http://skionrails.wordpress.com/2008/05/22/conditional-fragment-caching/
  def cache_if(condition, name={}, &block)
    if condition
      cache(name, &block)
    else
      block.call
    end
  end

  # Insert a chunk of +javascript+ into the page, and execute it when the document is ready.
  def insert_javascript(javascript)
    content_for(:javascript_insert) do
      <<-HERE
        <script>
          $(document).ready(function() {
            #{javascript}
          });
        </script>
      HERE
    end
  end

  # Focus cursor on DOM element specified by +xpath_query+ using JavaScript, e.g.:
  #
  #   <% focus_on '#search_field' %>
  def focus_on(xpath_query)
    insert_javascript "$('#{xpath_query}').focus();"
  end

  # Set the first tabindex to DOM element specified by +xpath_query+.
  def tabindex_on(xpath_query)
    #insert_javascript "$('#{xpath_query}')[0].tabindex = 1;"
    #insert_javascript "$('#{xpath_query}')[0].attributes['tabindex'] = 1;"
    # TODO Figure out how to set tabindex, because neither of these work right.
  end

  # Returns a string with safely encoded entities thanks to #h, while preserving any existing HTML entities.
  def cleanse(string)
    return escape_once(string)
  end

  def tag_links_for(model)
    model.tags.map{|tag| tag_link(model.class.name.downcase.to_sym, tag)}.join(', ')
  end

  def tag_link(type, tag, link_class=nil)
    internal_url = \
      case type
      when :event then search_events_path(:tag => tag.name)
      when :venue then venues_path(:tag => tag.name)
      end

    link_classes = [link_class]
    link_classes << "external #{tag.machine_tag[:namespace]} #{tag.machine_tag[:predicate]}" if tag.machine_tag[:url]

    link_to cleanse(tag.name), (tag.machine_tag[:url] || internal_url), :class => link_classes.compact.join(' ')
  end
end
