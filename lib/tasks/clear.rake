desc "Clear all caches: tmp, bundle, theme"
task :clear => ['tmp:cache:clear', 'server:clear', 'theme_remove_cache']
