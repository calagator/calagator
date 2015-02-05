module Calagator

module SourcesHelper
  # Return HTML with a link to the the external source URL.
  def source_url_link(source)
    return link_to source.url, source.url, { :rel => "nofollow", :target => "_BLANK" }
  end
end

end
