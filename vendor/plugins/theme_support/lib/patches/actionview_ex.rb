module ActionView
  class Base

    alias_method :theme_support_old_view_paths, :view_paths

    def view_paths
      paths = theme_support_old_view_paths

      if controller and controller.current_theme
        theme_path = File.join(RAILS_ROOT, "themes", controller.current_theme, "views")
        if File.exists?(theme_path) and ! paths.include?(theme_path)
          paths.unshift(theme_path)
        end
      end

      paths
    end
  end
end
