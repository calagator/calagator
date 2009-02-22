module ActionView::Helpers::AssetTagHelper

	def theme_stylesheet_path( source=nil, theme=nil )
		theme = theme || controller.current_theme
		compute_public_path(source || "theme", "themes/#{theme}/stylesheets", 'css')
	end

	def theme_image_path( source, theme=nil )
		theme = theme || controller.current_theme
		compute_public_path(source, "themes/#{theme}/images", 'png')
	end

  # FIXME a route is replacing this method??
	def theme_javascript_path( source, theme=nil )
		theme = theme || controller.current_theme
		compute_public_path(source, "themes/#{theme}/javascript", 'js')
	end
   
	def theme_javascripts_path( source, theme=nil )
		theme = theme || controller.current_theme
		compute_public_path(source, "themes/#{theme}/javascripts", 'js')
	end
   
	def theme_stylesheet_link_tag(*sources)
		sources.uniq!
		options = sources.last.is_a?(Hash) ? sources.pop.stringify_keys : { }
		sources.collect { |source|
			source = theme_stylesheet_path(source)
			tag("link", { "rel" => "Stylesheet", "type" => "text/css", "media" => "screen", "href" => source }.merge(options))
		}.join("\n")
	end

	def theme_image_tag(source, options = {})
		options.symbolize_keys
		options[:src] = theme_image_path(source)
		options[:alt] ||= File.basename(options[:src], '.*').split('.').first.capitalize
		if options[:size]
			options[:width], options[:height] = options[:size].split("x")
			options.delete :size
		end

		tag("img", options)
	end
   
	def theme_javascript_include_tag(*sources)
		options = sources.last.is_a?(Hash) ? sources.pop.stringify_keys : { }
		if sources.include?(:defaults)
			sources = sources[0..(sources.index(:defaults))] +
				@@javascript_default_sources.dup +
				sources[(sources.index(:defaults) + 1)..sources.length]
			sources.delete(:defaults)
			sources << "application" if defined?(RAILS_ROOT) && File.exists?("#{RAILS_ROOT}/public/javascripts/application.js")
		end
		sources.collect { |source|
      # FIXME theme_javascript_path is broken, so use the workaround for now
			# source = theme_javascript_path(source)
			source = theme_javascripts_path(source)
			content_tag("script", "", { "type" => "text/javascript", "src" => source }.merge(options))
		}.join("\n")
	end

end
