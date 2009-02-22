# = ThemeReader
#
# Returns name of the theme to use.

class ThemeReader
  def self.read
    rails_root = RAILS_ROOT rescue File.dirname(File.dirname(__FILE__))
    theme_txt = "#{rails_root}/config/theme.txt"
      if ENV["THEME"]
        ENV["THEME"]
      elsif File.exist?(theme_txt)
        File.read(theme_txt).strip
      else
        "default"
      end
  end
end
