class ActionController::Routing::RouteSet

	alias_method :__draw, :draw

	def draw
		clear!
		map = Mapper.new(self)
		create_theme_routes(map)
		yield map
		named_routes.install
	end

	def create_theme_routes(map)
		map.theme_images "/themes/:theme/images/*filename", :controller=>'theme', :action=>'images'
		map.theme_stylesheets "/themes/:theme/stylesheets/*filename", :controller=>'theme', :action=>'stylesheets'
		map.theme_javascript "/themes/:theme/javascript/*filename", :controller=>'theme', :action=>'javascript'
		map.connect "/themes/*whatever", :controller=>'theme', :action=>'error'
	end

end