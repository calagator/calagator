# frozen_string_literal: true

# = ThemeReader
#
# Returns name of the theme to use.

class ThemeReader
  def self.read
    rails_root = begin
      Rails.root
    rescue
      File.dirname(__FILE__, 2)
    end
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
