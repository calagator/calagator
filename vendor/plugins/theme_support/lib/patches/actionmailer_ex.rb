ActionMailer::Base.class_eval do 
  
	alias_method :__render, :render
	alias_method :__initialize, :initialize
	@current_theme = nil
	attr_reader :current_theme
   
	def initialize(method_name=nil, *parameters)
		if parameters[-1].is_a? Hash and (parameters[-1].include? :theme)
			@current_theme = parameters[-1][:theme]
			parameters[-1].delete :theme
			parameters[-1][:current_theme] = @current_theme
		end
		create!(method_name, *parameters) if method_name
	end
  
	def render(opts)
		body = opts.delete(:body)
		body[:current_theme] = @current_theme
		opts[:file] = "#{mailer_name}/#{opts[:file]}"
		initialize_template_class(body).render(opts)
	end
   
end