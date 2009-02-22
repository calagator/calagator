ActionController::Base.class_eval do 

	attr_accessor :current_theme
	attr_accessor :force_liquid_template

	def self.theme(theme_name, conditions = {})
		write_inheritable_attribute "theme", theme_name
	end

	def self.force_liquid(force_liquid_value, conditions = {})
		write_inheritable_attribute "force_liquid", force_liquid_value
	end

	def current_theme(passed_theme=nil)
		theme = passed_theme || self.class.read_inheritable_attribute("theme")
		@active_theme = case theme
		when Symbol then send(theme)
		when Proc   then theme.call(self)
		when String then theme
		end
	end

	def force_liquid_template(passed_value=nil)
		force_liquid = passed_value || self.class.read_inheritable_attribute("force_liquid")
		force_liquid_template = case force_liquid
        when Symbol then send(force_liquid)
        when Proc   then force_liquid.call(self)
        when String then force_liquid == 'true'
        when TrueClass then force_liquid
        when FalseClass then force_liquid
        when Fixnum then force_liquid == 1
		end
	end

end