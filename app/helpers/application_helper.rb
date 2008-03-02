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
    format.gsub!(/(%[dHImU])/,'*\1')
    time.strftime(format).gsub(/\*0*/,'')
  end
end
