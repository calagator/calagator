desc "Clear all caches"
task :clear => ['tmp:cache:clear', 'server:clear', 'theme_remove_cache']
