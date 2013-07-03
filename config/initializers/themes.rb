Calagator::Application.configure do
  # add theme-specific asset directories to the asset pipeline
  theme_dir   = Rails.root.join('themes', ::THEME_NAME)
  asset_paths = Dir[theme_dir.join('{javascripts,stylesheets,images}')]
  config.assets.paths.prepend(*asset_paths)

  # assets to include from theme when compiling assets (rake assets:precompile)
  config.assets.precompile += %w(theme.js theme.css)
  config.assets.precompile += ::SETTINGS.precompile_assets || []
end
