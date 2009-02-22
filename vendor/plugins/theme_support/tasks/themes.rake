desc "Creates the cached (public) theme folders"
task :theme_create_cache do
	for theme in Dir.glob("#{RAILS_ROOT}/themes/*")
		theme_name = theme.split( File::Separator )[-1]
		puts "Creating #{RAILS_ROOT}/public/themes/#{theme_name}"
		FileUtils.mkdir_p "#{RAILS_ROOT}/public/themes/#{theme_name}"
		FileUtils.cp_r "#{theme}/images", "#{RAILS_ROOT}/public/themes/#{theme_name}/images", :verbose => true
		FileUtils.cp_r "#{theme}/stylesheets", "#{RAILS_ROOT}/public/themes/#{theme_name}/stylesheets", :verbose => true
		FileUtils.cp_r "#{theme}/javascript", "#{RAILS_ROOT}/public/themes/#{theme_name}/javascript", :verbose => true
	end
end

desc "Removes the cached (public) theme folders"
task :theme_remove_cache do
	puts "Removing #{RAILS_ROOT}/public/themes"
	FileUtils.rm_r "#{RAILS_ROOT}/public/themes", :force => true
end

desc "Updates the cached (public) theme folders"
task :theme_update_cache => [:theme_remove_cache, :theme_create_cache]