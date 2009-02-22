class ThemeGenerator < Rails::Generator::NamedBase
     
   def manifest
      record do |m|
          # Theme folder(s)
          m.directory File.join( "themes", file_name )
          # theme content folders
          m.directory File.join( "themes", file_name, "images" )
          m.directory File.join( "themes", file_name, "javascript" )
          m.directory File.join( "themes", file_name, "layouts" )
          m.directory File.join( "themes", file_name, "views" )
          m.directory File.join( "themes", file_name, "stylesheets" )
          # Default files...
          # about
          m.template 'about.markdown', File.join( 'themes', file_name, 'about.markdown' )
          # image
          m.file 'screenshot.png', File.join( 'themes', file_name, 'images', 'screenshot.png' )
          # stylesheet
          m.template "theme.css", File.join( "themes", file_name, "stylesheets", "screen.css" )
          # layouts
          m.template 'layout.rhtml', File.join( 'themes', file_name, 'layouts', 'site.rhtml' )
          #m.template 'layout.liquid', File.join( 'themes', file_name, 'layouts', 'default.liquid' )
          # view readme
          m.template 'views_readme', File.join( 'themes', file_name, 'views', 'views_readme.txt' )
      end
   end
end