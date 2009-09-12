module ThemeSupport
  module ControllerExtensions

    def self.included(klass)
      klass.send :extend, ClassMethods
      klass.helper_method :current_theme
      klass.send :alias_method, :theme_support_active_layout, :active_layout
      klass.send :include, InstanceMethods
    end

    module ClassMethods
      # Use this in your controller just like the <tt>layout</tt> macro.
      # Example:
      #
      #  theme 'theme_name'
      #
      # -or-
      #
      #  theme :get_theme
      #
      #  def get_theme
      #    'theme_name'
      #  end
      def theme(theme_name, conditions = {})
        # TODO: Allow conditions... (?)
        write_inheritable_attribute "theme", theme_name
      end
    end

    module InstanceMethods
      attr_accessor :current_theme
      attr_accessor :force_liquid_template

      # Retrieves the current set theme

      def current_theme(passed_theme = nil)
        @current_theme ||= get_current_theme(passed_theme)
      end

      def get_current_theme(passed_theme=nil)
        theme = passed_theme || self.class.read_inheritable_attribute("theme")

        @active_theme = case theme
          when Symbol then send(theme)
          when Proc   then theme.call(self)
          when String then theme
        end
      end

      def active_layout(passed_layout = nil, options = {})
        if current_theme
          theme_path = File.join(RAILS_ROOT, "themes", current_theme, "views")
          if File.exists?(theme_path) and ! self.class.view_paths.include?(theme_path)
            self.class.view_paths.unshift(theme_path)
            result = theme_support_active_layout(passed_layout)
            self.class.view_paths.shift
            return result
          end
        end

        theme_support_active_layout(passed_layout, options)
      end
    end
  end
end
