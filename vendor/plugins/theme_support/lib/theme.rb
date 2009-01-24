class Theme

	cattr_accessor :cache_theme_lookup
	@@cache_theme_lookup = false

	attr_accessor :name, :title, :description, :preview_image

	def initialize(name)
		@name = name
		@title = name.underscore.humanize.titleize
		@description_html = nil
	end
 
	def description
		if @description_html.nil?
			@description_html = RedCloth.new(File.read( File.join(Theme.path_to_theme(name), "about.markdown") )).to_html(:markdown, :textile) rescue "#{title}"
		end
		@description_html
	end
  
	def has_preview?
		File.exists?( File.join( Theme.path_to_theme(name), 'images', 'screenshot.png' ) ) rescue false
	end
  
	def preview_image
		'preview.png'
	end
    
	def self.find_all
		installed_themes.inject([]) do |array, path|
			array << theme_from_path(path)
		end
	end

	private

	def self.themes_root
		File.join(RAILS_ROOT, "themes")
	end

	def self.path_to_theme(theme)
		File.join(themes_root, theme)
	end

	def self.theme_from_path(path)
		name = path.scan(/[-\w]+$/i).flatten.first
		self.new(name)
	end

	def self.installed_themes
		cache_theme_lookup ? @theme_cache ||= search_theme_directory : search_theme_directory
	end

	def self.search_theme_directory
		Dir.glob("#{themes_root}/[-_a-zA-Z0-9]*").collect do |file|
			file if File.directory?(file)
		end.compact
	end

end