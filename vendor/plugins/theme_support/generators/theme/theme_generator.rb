class ThemeGenerator < Rails::Generator::NamedBase

   def manifest
      record do |m|
          # Theme folder(s)
          m.directory File.join( "themes", file_name )
          # theme content folders
          m.directory File.join( "themes", file_name, "images" )
          m.directory File.join( "themes", file_name, "javascript" )
          m.directory File.join( "themes", file_name, "views" )
          m.directory File.join( "themes", file_name, "views", "layouts" )
          m.directory File.join( "themes", file_name, "stylesheets" )
          # Default files...
          # about
          m.template 'about.markdown', File.join( 'themes', file_name, 'about.markdown' )
          # image
          m.file 'preview.png', File.join( 'themes', file_name, 'images', 'preview.png' )
          # stylesheet
          m.template "theme.css", File.join( "themes", file_name, "stylesheets", "#{file_name}.css" )
          # layouts
          m.template 'layout.html.erb', File.join( 'themes', file_name, 'views', 'layouts', 'default.html.erb' )
          #m.template 'layout.liquid', File.join( 'themes', file_name, 'layouts', 'default.liquid' )
          # view readme
          m.template 'views_readme', File.join( 'themes', file_name, 'views', 'views_readme.txt' )
      end
   end
end