ThemesForRails.config do |config|
  # your static assets on Rails.root/themes/pink/assets/{stylesheets,javascripts,images}
  config.assets_dir = ":root/themes/:name"

  # UPSTREAM BUG: the themes:create_cache rake task in the ThemesForRails
  # gem has a bug when trying to figure out where to copy assets; it
  # assumes the themes directory is a relative path w/o a ':root'
  # placeholder, even though the gem's default is ':root/themes'. This
  # line can be removed once it has been determined that the rake task
  # has been fixed upstream.
  config.themes_dir = 'themes'
end
