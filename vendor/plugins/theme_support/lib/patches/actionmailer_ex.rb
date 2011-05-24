# Extend the Base ActionMailer to support themes
module ActionMailer
  class Base
   
    def initialize(method_name=nil, *parameters)
      if parameters[-1].is_a?(Hash) and (parameters[-1].include? :theme)
        @current_theme = parameters[-1][:theme]
        parameters[-1].delete :theme
        parameters[-1][:current_theme] = @current_theme
      end
      create!(method_name, *parameters) if method_name
    end

    def create!(method_name, *parameters) #:nodoc:
      initialize_defaults(method_name)
      __send__(method_name, *parameters)

      tpaths = []
      theme_template_roots = {}

      if self.current_theme
        path = File.join(RAILS_ROOT, "themes", self.current_theme, "views", mailer_name)
        tpaths << path
        theme_template_roots[path] = ActionView::Base.process_view_paths(File.dirname(path)).first
      end

      # NOTE: Fixed use of #template_path, because plugins apparently return an absolute path, whereas normal views have relative paths, and the original, commented-out code didn't distinguish between these:
      #IK# tpaths << File.join(RAILS_ROOT, template_path)
      #IK# theme_template_roots[File.join(RAILS_ROOT, template_path)] = template_root
      absolute_template_path =
        Pathname.new(template_path).absolute? ?
          template_path :
          File.join(RAILS_ROOT, template_path)
      tpaths << absolute_template_path
      theme_template_roots[absolute_template_path] = template_root

      # If an explicit, textual body has not been set, we check assumptions.
      unless String === @body
        # First, we look to see if there are any likely templates that match,
        # which include the content-type in their file name (i.e.,
        # "the_template_file.text.html.erb", etc.). Only do this if parts
        # have not already been specified manually.

        if @parts.empty?

          tpaths.each do |tpath|
            Dir.glob("#{tpath}/#{@template}.*").each do |path|
              template = theme_template_roots[tpath]["#{mailer_name}/#{File.basename(path)}"]

              # Skip unless template has a multipart format
              next unless template && template.multipart?

              @parts << Part.new(
                :content_type => template.content_type,
                :disposition => "inline",
                :charset => charset,
                :body => render_message(template, @body)
              )
            end
            break if @parts.any?
          end
          unless @parts.empty?
            @content_type = "multipart/alternative"
            @parts = sort_parts(@parts, @implicit_parts_order)
          end
        end

        # Then, if there were such templates, we check to see if we ought to
        # also render a "normal" template (without the content type). If a
        # normal template exists (or if there were no implicit parts) we render
        # it.
        template_exists = @parts.empty?
        tpaths.each do |tpath|
          template_exists ||= template_root["#{tpath}/#{@template}"]
          if template_exists
            @body = render_message(@template, @body)
            break
          end
        end

        # Finally, if there are other message parts and a textual body exists,
        # we shift it onto the front of the parts and set the body to nil (so
        # that create_mail doesn't try to render it in addition to the parts).
        if !@parts.empty? && String === @body
          @parts.unshift Part.new(:charset => charset, :body => @body)
          @body = nil
        end
      end

      # If this is a multipart e-mail add the mime_version if it is not
      # already set.
      @mime_version ||= "1.0" if !@parts.empty?

      # build the mail object itself
      @mail = create_mail
    end
  end
end
