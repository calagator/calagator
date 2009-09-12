module ThemeSupport
  module RoutingExtensions
    def themeing
      @set.with_options :controller => 'theme' do |theme|
        theme.add_named_route 'theme_images',
          '/themes/:theme/images/*filename', :action => 'images'

        theme.add_named_route 'theme_stylesheets',
          '/themes/:theme/stylesheets/*filename', :action => 'stylesheets'

        theme.add_named_route 'theme_javascript',
          '/themes/:theme/javascript/*filename', :action => 'javascript'

        theme.add_route '/themes/*whatever', :action => 'error'
      end
    end
  end
end

ActionController::Routing::RouteSet::Mapper.send :include, ThemeSupport::RoutingExtensions
